-- Onboarding vs Reactivation
-- define each rider onnboarding date,select OA - map to cluster, OV onboarding date + 1 week etc...
-- use variable for starting date
SET start_date = TO_DATE('2025-02-07');

WITH ONBOARDING AS (
    SELECT
        LS.COUNTRY_NAME,
        LS.onboarding_area,
        LS.RIDER_DRN,
        SUBSTR(LS.RIDER_DRN, 18) AS UUID,
        dad.driver_id,
        TO_CHAR(TO_DATE(CASE WHEN LS.LIFECYCLE_MAIN_STAGE = 'application' AND LS.STAGE_STATUS ILIKE '%completed%' THEN GREATEST(LS.EVENT_UPDATED_AT, LS.EVENT_CREATED_AT) END), 'YYYY-MM-DD') AS onboarding_at_date,
        TO_CHAR(TO_DATE(LS.CREATED_IN_RIDER_ADMIN_AT), 'YYYY-MM-DD') AS created_in_rider_admin_at_date,
        dad.rider_admin_status_note,
        dad.CUR_ADMIN_STATUS,
        LS.VEHICLE_TYPE
    FROM "RIDERS"."RIDER_LIFECYCLE_LATEST_STATUS" AS LS
    LEFT JOIN "RIDERS"."RIDER_LIFECYCLE_LATEST_ONBOARDING_PHASE" AS OP 
        ON (CASE WHEN 'yes' = 'yes' THEN LS.RIDER_DRN ELSE MD5(LS.RIDER_DRN) END) = (CASE WHEN 'yes' = 'yes' THEN OP.RIDER_DRN ELSE MD5(OP.RIDER_DRN) END)
        AND LS.LIFECYCLE_MAIN_STAGE = OP.LIFECYCLE_STAGE
    LEFT JOIN production.denormalised.driver_accounting_daily AS dad ON dad.driver_uuid = SUBSTR(LS.RIDER_DRN, 18)
    WHERE 
        onboarding_at_date >= $start_date
        AND created_in_rider_admin_at_date >= $start_date
        AND LS.ONBOARDING_PLATFORM = 'salesforce'
        AND LS.COUNTRY_NAME IN ('Ireland', 'UK')
        AND onboarding_at_date < DATEADD(WEEK, -5, CURRENT_DATE)
        AND created_in_rider_admin_at_date < DATEADD(WEEK, -5, CURRENT_DATE)
        AND dad.DATE >= TO_DATE(DATEADD('day', -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
        AND dad.DATE < TO_DATE(DATEADD('day', 1, DATEADD('day', -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))))

        AND is_substitute_account_on_admin = false
        AND is_returner = false
       
    GROUP BY
        TO_DATE(LS.CREATED_IN_RIDER_ADMIN_AT),
        TO_DATE(CASE WHEN LS.LIFECYCLE_MAIN_STAGE = 'application' AND LS.STAGE_STATUS ILIKE '%completed%' THEN GREATEST(LS.EVENT_UPDATED_AT, LS.EVENT_CREATED_AT) END),
        LS.COUNTRY_NAME,
        LS.onboarding_area,
        LS.rider_drn,
        UUID,
        dad.rider_admin_status_note,
        dad.CUR_ADMIN_STATUS,
        dad.driver_id,
        LS.VEHICLE_TYPE
    ORDER BY
        LS.COUNTRY_NAME DESC,
        dad.driver_id
)

SELECT
    A.COUNTRY_NAME,
    A.onboarding_area,
    A.driver_id,
    A.onboarding_at_date,
    A.CUR_ADMIN_STATUS,
    A.VEHICLE_TYPE,
    SUM(CASE WHEN OA_STATUS = 'DELIVERED' THEN 1 ELSE 0 END) AS ORDER_COUNT,
    SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN onboarding_at_date AND DATEADD(DAY, 6, onboarding_at_date) THEN 1 ELSE 0 END) AS W1,
    SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN DATEADD(DAY, 7, onboarding_at_date) AND DATEADD(DAY, 14, onboarding_at_date) THEN 1 ELSE 0 END) AS W2,
    SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN DATEADD(DAY, 15, onboarding_at_date) AND DATEADD(DAY, 21, onboarding_at_date) THEN 1 ELSE 0 END) AS W3,
    SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN DATEADD(DAY, 22, onboarding_at_date) AND DATEADD(DAY, 28, onboarding_at_date) THEN 1 ELSE 0 END) AS W4,
    SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN DATEADD(DAY, 29, onboarding_at_date) AND DATEADD(DAY, 35, onboarding_at_date) THEN 1 ELSE 0 END) AS W5,
    SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN DATEADD(DAY, 36, onboarding_at_date) AND DATEADD(DAY, 42, onboarding_at_date) THEN 1 ELSE 0 END) AS W6,
    SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN DATEADD(DAY, 43, onboarding_at_date) AND DATEADD(DAY, 49, onboarding_at_date) THEN 1 ELSE 0 END) AS W7

FROM ONBOARDING AS A
LEFT JOIN production.denormalised.denormalised_assignment AS B ON A.DRIVER_ID = B.DRIVER_ID
WHERE B.COUNTRY_NAME IN ('UK', 'Ireland')
  AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) >= A.onboarding_at_date
GROUP BY 
    A.COUNTRY_NAME,
    A.onboarding_area,
    A.driver_id,
    A.onboarding_at_date,
    A.CUR_ADMIN_STATUS,
    A.VEHICLE_TYPE

;

