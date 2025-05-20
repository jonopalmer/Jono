SET start_date = TO_DATE('2023-11-01');



-- Checks DAD for status changes for each driver and orders delivered cumulative
CREATE OR REPLACE TEMPORARY TABLE status_changes AS (
    SELECT 
        driver_id,
        driver_uuid,
        orders_delivered_cumulative,
        rider_admin_status_note,
        CUR_ADMIN_STATUS,
        DATE,
        LAG(rider_admin_status_note) OVER (PARTITION BY driver_id ORDER BY DATE) as prev_note,
        LAG(CUR_ADMIN_STATUS) OVER (PARTITION BY driver_id ORDER BY DATE) as prev_status,
        ROW_NUMBER() OVER (PARTITION BY driver_id, rider_admin_status_note, CUR_ADMIN_STATUS ORDER BY DATE) as status_occurrence
    FROM production.denormalised.driver_accounting_daily AS DAD 
    WHERE dad.DATE >= $start_date AND CUR_COUNTRY IN ('Ireland', 'UK')
);



CREATE OR REPLACE TEMPORARY TABLE distinct_statuses AS (
SELECT 
    driver_id,
    driver_uuid,
    orders_delivered_cumulative, 
    rider_admin_status_note,
    CUR_ADMIN_STATUS,
    DATE
FROM status_changes
WHERE 
    (rider_admin_status_note IS DISTINCT FROM prev_note)
    OR (CUR_ADMIN_STATUS IS DISTINCT FROM prev_status)
    OR prev_note IS NULL  -- Keep the first record for each driver
    AND status_occurrence = 1  -- Only keep the first occurrence of each status
);
-- SELECT * FROM STATUS_CHANGES;

-- Joins Onboarding data with data on status changes and orders delivered cumulative
-- Also filters for drivers that have had at least 5 weeks to activate, not subs or returner 
CREATE OR REPLACE TEMPORARY TABLE disabled_onboards AS (
WITH first_onboarding AS (
    SELECT 
        LS.RIDER_DRN,
        MIN(TO_DATE(CASE WHEN LS.LIFECYCLE_MAIN_STAGE = 'application' AND LS.STAGE_STATUS ILIKE '%completed%' 
            THEN GREATEST(LS.EVENT_UPDATED_AT, LS.EVENT_CREATED_AT) END)) as first_onboarding_date,
        MIN(TO_DATE(LS.CREATED_IN_RIDER_ADMIN_AT)) as first_created_date
    FROM "RIDERS"."RIDER_LIFECYCLE_LATEST_STATUS" AS LS
    WHERE LS.COUNTRY_NAME IN ('Ireland', 'UK')
    GROUP BY LS.RIDER_DRN
)
SELECT DISTINCT
        LS.COUNTRY_NAME,
        LS.onboarding_area,
        LS.CITY,
        DS.driver_id,
        DS.orders_delivered_cumulative,
        DS.rider_admin_status_note,
        DS.CUR_ADMIN_STATUS,
        DS.DATE AS status_date,
        FO.first_onboarding_date AS onboarding_at_date,
        FO.first_created_date AS created_in_rider_admin_at_date,
        DATEDIFF('day', FO.first_onboarding_date, CURRENT_DATE()) AS days_since_onboarding,
        DATEDIFF('day', FO.first_onboarding_date, DS.DATE) AS days_since_onboard_status_change,
        LS.VEHICLE_TYPE
    FROM "RIDERS"."RIDER_LIFECYCLE_LATEST_STATUS" AS LS
    LEFT JOIN "RIDERS"."RIDER_LIFECYCLE_LATEST_ONBOARDING_PHASE" AS OP
        ON (CASE WHEN 'yes' = 'yes' THEN LS.RIDER_DRN ELSE MD5(LS.RIDER_DRN) END) = (CASE WHEN 'yes' = 'yes' THEN OP.RIDER_DRN ELSE MD5(OP.RIDER_DRN) END)
        AND LS.LIFECYCLE_MAIN_STAGE = OP.LIFECYCLE_STAGE
    LEFT JOIN distinct_statuses AS DS ON DS.driver_uuid = SUBSTR(LS.RIDER_DRN, 18)
    LEFT JOIN first_onboarding FO ON FO.RIDER_DRN = LS.RIDER_DRN
    WHERE 
        FO.first_onboarding_date >= $start_date
        AND FO.first_created_date >= $start_date
        AND LS.ONBOARDING_PLATFORM = 'salesforce'
        AND LS.COUNTRY_NAME IN ('Ireland', 'UK')
        AND is_substitute_account_on_admin = false
        AND OP.is_returner = false
        AND DS.DATE >= FO.first_onboarding_date
    ORDER BY DS.driver_id, DS.DATE
);
-- SELECT * FROM disabled_onboards order by ONBOARDING_AT_DATE;







-- Table with one row per driver, giving key dates and statuses
CREATE OR REPLACE TEMPORARY TABLE FULL_DATA AS (
WITH first_disabled AS (
    SELECT DISTINCT
        driver_id,
        MIN(CASE WHEN CUR_ADMIN_STATUS = 'DISABLED' THEN STATUS_DATE END) as first_disabled_date,
        MIN(CASE WHEN CUR_ADMIN_STATUS = 'DISABLED' THEN RIDER_ADMIN_STATUS_NOTE END) as first_disabled_note,
        MIN(CASE WHEN CUR_ADMIN_STATUS = 'DISABLED' THEN ORDERS_DELIVERED_CUMULATIVE END) as orders_at_disabled
    FROM disabled_onboards
    GROUP BY driver_id
),
first_terminated AS (
    SELECT DISTINCT
        driver_id,
        MIN(CASE WHEN CUR_ADMIN_STATUS = 'TERMINATED' THEN STATUS_DATE END) as first_terminated_date
    FROM disabled_onboards
    GROUP BY driver_id
),
latest_status AS (
    SELECT DISTINCT
        driver_id,
        LAST_VALUE(CUR_ADMIN_STATUS) OVER (PARTITION BY driver_id ORDER BY STATUS_DATE ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as latest_status,
        LAST_VALUE(ORDERS_DELIVERED_CUMULATIVE) OVER (PARTITION BY driver_id ORDER BY STATUS_DATE ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as latest_orders
    FROM disabled_onboards
),
disabled_to_approved AS (
    SELECT DISTINCT
        a.driver_id,
        MIN(b.STATUS_DATE) as first_approved_after_disabled
    FROM disabled_onboards a
    JOIN disabled_onboards b 
        ON a.driver_id = b.driver_id 
        AND b.STATUS_DATE > a.STATUS_DATE
        AND b.CUR_ADMIN_STATUS = 'APPROVED'
    WHERE a.CUR_ADMIN_STATUS = 'DISABLED'
    GROUP BY a.driver_id
),
first_onboard AS (
    SELECT 
        driver_id,
        MIN(ONBOARDING_AT_DATE) as first_onboard_date
    FROM disabled_onboards
    GROUP BY driver_id
)

SELECT DISTINCT
    d.COUNTRY_NAME,
    d.ONBOARDING_AREA,
    d.CITY,
    d.VEHICLE_TYPE,
    d.driver_id,
    fo.first_onboard_date as onboard_date, -- Date driver completed first onboarding
    fd.first_disabled_date as disabled_date, -- First date driver was disabled
    fd.first_disabled_note as disabled_reason, -- Admin note explaining why driver was disabled
    fd.orders_at_disabled as orders_at_disable, -- Cumulative orders when disabled
    da.first_approved_after_disabled as reapproved_date, -- First date driver was re-approved after being disabled
    ft.first_terminated_date as terminated_date, -- First date driver was terminated
    ls.latest_status as current_status, -- Most recent admin status
    ls.latest_orders as current_orders, -- Current cumulative orders
    -- Date difference calculations
    NULLIF(GREATEST(0, DATEDIFF('day', fo.first_onboard_date, fd.first_disabled_date)), 0) as days_to_disable, -- Days between onboarding and first disable
    NULLIF(GREATEST(0, DATEDIFF('day', fd.first_disabled_date, da.first_approved_after_disabled)), 0) as days_to_reapprove, -- Days between disable and re-approval
    NULLIF(GREATEST(0, DATEDIFF('day', fd.first_disabled_date, CURRENT_DATE())), 0) as days_since_disable, -- Days since first disable
    NULLIF(GREATEST(0, DATEDIFF('day', fo.first_onboard_date, CURRENT_DATE())), 0) as days_since_onboard, -- Days since onboarding
    NULLIF(GREATEST(0, DATEDIFF('day', fo.first_onboard_date, ft.first_terminated_date)), 0) as days_to_terminate -- Days between re-approval and termination
FROM (
    SELECT DISTINCT
        COUNTRY_NAME,
        ONBOARDING_AREA,
        CITY,
        VEHICLE_TYPE,
        driver_id
    FROM disabled_onboards
) d
LEFT JOIN first_onboard fo ON fo.driver_id = d.driver_id
LEFT JOIN first_disabled fd ON fd.driver_id = d.driver_id
LEFT JOIN first_terminated ft ON ft.driver_id = d.driver_id
LEFT JOIN latest_status ls ON ls.driver_id = d.driver_id
LEFT JOIN disabled_to_approved da ON da.driver_id = d.driver_id
WHERE 
    fo.first_onboard_date >= $start_date
ORDER BY d.driver_id, onboarding_area, city, vehicle_type
);

-- Remove duplicate drivers
CREATE OR REPLACE TEMPORARY TABLE UNIQUE_DRIVERS AS (
    SELECT *
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY driver_id ORDER BY onboard_date, onboarding_area, city, vehicle_type) as rn
        FROM FULL_DATA
    )
    WHERE rn = 1
);



-- select * from UNIQUE_DRIVERS order by onboard_date limit 100;

-- select count(distinct driver_id) from FULL_DATA;


-- select distinct CURRENT_STATUS from UNIQUE_DRIVERS

-- Create monthly cohort analysis table

CREATE OR REPLACE TEMPORARY TABLE MONTHLY_COHORT_ANALYSIS AS (
    SELECT 
        COUNTRY_NAME,
        DATE_TRUNC('month', onboard_date) as ONBOARD_MONTH,
        -- Total number of riders who onboarded in this month
        COUNT(DISTINCT driver_id) as total_onboards,
        
        -- Total number of riders who were disabled at least once
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL THEN driver_id END) as disabled_riders,
        
        -- Disabled riders with different order thresholds
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND orders_at_disable >= 1 THEN driver_id END) as disabled_with_1_order,
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND orders_at_disable >= 10 THEN driver_id END) as disabled_with_10_orders,
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND orders_at_disable >= 50 THEN driver_id END) as disabled_with_50_orders,
        
        -- Average days from onboard to disabled
        ROUND(AVG(CASE WHEN days_to_disable IS NOT NULL THEN days_to_disable END), 2) as avg_days_to_disable,
        
        -- Disabled within 28 days
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND days_to_disable <= 28 THEN driver_id END) as disabled_within_28d,
        
        -- Disabled within 28 days with 1 order
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND days_to_disable <= 28 AND orders_at_disable >= 1 THEN driver_id END) as disabled_28d_with_1_order,
        
        -- Conditional onboarding grace period expired
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' THEN driver_id END) as disabled_grace_period_expired,
        
        -- Reapproval metrics
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN reapproved_date IS NOT NULL THEN driver_id END) / 
            NULLIF(COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL THEN driver_id END), 0), 2) as reapproval_rate,
        ROUND(AVG(CASE WHEN days_to_reapprove IS NOT NULL THEN days_to_reapprove END), 2) as avg_days_to_reapprove,
        
        -- Termination metrics
        COUNT(DISTINCT CASE WHEN terminated_date IS NOT NULL THEN driver_id END) as terminated_riders,
        
        -- Current status metrics
        COUNT(DISTINCT CASE WHEN current_status = 'DISABLED' THEN driver_id END) as current_disabled,
        COUNT(DISTINCT CASE WHEN current_status IN ('DISABLED', 'TERMINATED') THEN driver_id END) as current_disabled_or_terminated
    FROM UNIQUE_DRIVERS
    GROUP BY COUNTRY_NAME, DATE_TRUNC('month', onboard_date)
    ORDER BY COUNTRY_NAME, ONBOARD_MONTH
);

-- Display the results with column descriptions
SELECT 
    COUNTRY_NAME,
    ONBOARD_MONTH,
    total_onboards, -- Total number of riders who onboarded in this month
    disabled_riders/total_onboards as disabled_rate, -- Total number of riders who were disabled at least once
    disabled_with_1_order/total_onboards as disabled_with_1_order_rate, -- Disabled riders who delivered at least 1 order
    disabled_with_10_orders/total_onboards as disabled_with_10_orders_rate, -- Disabled riders who delivered at least 10 orders
    disabled_with_50_orders/total_onboards as disabled_with_50_orders_rate, -- Disabled riders who delivered at least 50 orders
    avg_days_to_disable, -- Average number of days between onboard and disable
    disabled_within_28d/total_onboards as disabled_within_28d_rate, -- Number of riders disabled within 28 days of onboarding
    disabled_grace_period_expired/total_onboards as disabled_grace_period_expired_rate, -- Number of riders disabled due to grace period expiration
    reapproval_rate/100 as reapproval_rate, -- Percentage of disabled riders who were reapproved
    avg_days_to_reapprove, -- Average number of days between disable and reapproval
    terminated_riders/total_onboards as terminated_rate, -- Total number of riders terminated at least once
    current_disabled/total_onboards as current_disabled_rate, -- Current number of riders with status DISABLED
FROM MONTHLY_COHORT_ANALYSIS
order by country_name desc, onboard_month desc;









-- Create monthly cohort analysis table -- FILTER FOR GRACE PERIOD EXPIRED

CREATE OR REPLACE TEMPORARY TABLE MONTHLY_COHORT_ANALYSIS AS (
    SELECT 
        COUNTRY_NAME,
        DATE_TRUNC('month', onboard_date) as ONBOARD_MONTH,
        -- Total number of riders who onboarded in this month
        COUNT(DISTINCT driver_id) as total_onboards,
        
        -- Total number of riders who were disabled at least once
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' THEN driver_id END) as disabled_riders,
        
        -- Disabled riders with different order thresholds
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' AND orders_at_disable >= 1 THEN driver_id END) as disabled_with_1_order,
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' AND orders_at_disable >= 10 THEN driver_id END) as disabled_with_10_orders,
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' AND orders_at_disable >= 50 THEN driver_id END) as disabled_with_50_orders,
        
        -- Average days from onboard to disabled
        ROUND(AVG(CASE WHEN days_to_disable IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' THEN days_to_disable END), 2) as avg_days_to_disable,
        
        -- Disabled within 28 days
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' AND days_to_disable <= 28 THEN driver_id END) as disabled_within_28d,
        
        -- Disabled within 28 days with 1 order
        COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' AND days_to_disable <= 28 AND orders_at_disable >= 1 THEN driver_id END) as disabled_28d_with_1_order,
        
        -- Reapproval metrics
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN reapproved_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' THEN driver_id END) / 
            NULLIF(COUNT(DISTINCT CASE WHEN disabled_date IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' THEN driver_id END), 0), 2) as reapproval_rate,
        ROUND(AVG(CASE WHEN days_to_reapprove IS NOT NULL AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' THEN days_to_reapprove END), 2) as avg_days_to_reapprove,
        
        -- Current status metrics
        COUNT(DISTINCT CASE WHEN current_status = 'DISABLED' AND disabled_reason ILIKE '%Conditional onboarding grace period expired%' THEN driver_id END) as current_disabled
    FROM UNIQUE_DRIVERS
    GROUP BY COUNTRY_NAME, DATE_TRUNC('month', onboard_date)
    ORDER BY COUNTRY_NAME, ONBOARD_MONTH
);

-- Display the results with column descriptions
SELECT 
    COUNTRY_NAME,
    ONBOARD_MONTH,
    total_onboards, -- Total number of riders who onboarded in this month
    disabled_riders/total_onboards as disabled_rate, -- Total number of riders who were disabled at least once
    disabled_with_1_order/total_onboards as disabled_with_1_order_rate, -- Disabled riders who delivered at least 1 order
    disabled_with_10_orders/total_onboards as disabled_with_10_orders_rate, -- Disabled riders who delivered at least 10 orders
    disabled_with_50_orders/total_onboards as disabled_with_50_orders_rate, -- Disabled riders who delivered at least 50 orders
    avg_days_to_disable, -- Average number of days between onboard and disable
    disabled_within_28d/total_onboards as disabled_within_28d_rate, -- Number of riders disabled within 28 days of onboarding
    reapproval_rate/100 as reapproval_rate, -- Percentage of disabled riders who were reapproved
    avg_days_to_reapprove, -- Average number of days between disable and reapproval
    current_disabled/total_onboards as current_disabled_rate -- Current number of riders with status DISABLED
FROM MONTHLY_COHORT_ANALYSIS
order by country_name desc, onboard_month desc;






