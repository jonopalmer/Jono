
SELECT DISTINCT onboarding_phase
FROM "RIDERS"."RIDER_LIFECYCLE_LATEST_STATUS"
LIMIT 500;

WITH filtered_riders AS (
    SELECT
        COUNTRY_NAME,
        onboarding_area,
        RIDER_DRN,
        GREATEST(EVENT_UPDATED_AT, EVENT_CREATED_AT) AS latest_event_date,
        is_substitute_account_on_admin
    FROM "RIDERS"."RIDER_LIFECYCLE_LATEST_STATUS"
    WHERE LIFECYCLE_MAIN_STAGE = 'application'
      AND STAGE_STATUS ILIKE '%completed%'
      AND ONBOARDING_PLATFORM = 'salesforce'
      AND COUNTRY_NAME IN ('Ireland', 'UK')
)
SELECT
    COUNTRY_NAME,
    onboarding_area,
    RIDER_DRN,
    is_substitute_account_on_admin,
    IS_RETURNER
FROM filtered_riders A
LEFT JOIN "RIDERS"."RIDER_LIFECYCLE_LATEST_ONBOARDING_PHASE" B ON A.RIDER_DRN = B.RIDER_DRN
WHERE latest_event_date >= DATEADD('day', -7, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
  AND latest_event_date < DATEADD('day', 7, DATEADD('day', -7, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))))
GROUP BY
    COUNTRY_NAME, onboarding_area, RIDER_DRN, is_substitute_account_on_admin, IS_RETURNER
ORDER BY 
    COUNTRY_NAME DESC, onboarding_area, RIDER_DRN;

SELECT *
FROM "RIDERS"."RIDER_LIFECYCLE_LATEST_ONBOARDING_PHASE"
LIMIT 10;

SELECT
    A.COUNTRY_NAME,
    A.onboarding_area,
    A.RIDER_DRN,
    CASE WHEN A.is_substitute_account_on_admin THEN 'Yes' ELSE 'No' END AS is_substitute_account_on_admin,
    CASE WHEN IFNULL(B.IS_RETURNER, FALSE) THEN 'Yes' ELSE 'No' END AS is_returner
FROM "RIDERS"."RIDER_LIFECYCLE_LATEST_STATUS" A
LEFT JOIN "RIDERS"."RIDER_LIFECYCLE_LATEST_ONBOARDING_PHASE" B 
    ON (CASE WHEN 'yes' = 'yes' THEN A.RIDER_DRN ELSE MD5(A.RIDER_DRN) END) = 
       (CASE WHEN 'yes' = 'yes' THEN B.RIDER_DRN ELSE MD5(B.RIDER_DRN) END)
    AND A.LIFECYCLE_MAIN_STAGE = B.LIFECYCLE_STAGE
WHERE 
    CASE WHEN A.LIFECYCLE_MAIN_STAGE = 'application' AND A.STAGE_STATUS ILIKE '%completed%' 
         THEN GREATEST(A.EVENT_UPDATED_AT, A.EVENT_CREATED_AT) END >= 
         DATEADD('day', -7, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
    AND CASE WHEN A.LIFECYCLE_MAIN_STAGE = 'application' AND A.STAGE_STATUS ILIKE '%completed%' 
         THEN GREATEST(A.EVENT_UPDATED_AT, A.EVENT_CREATED_AT) END < 
         DATEADD('day', 7, DATEADD('day', -7, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))))
    AND A.ONBOARDING_PLATFORM = 'salesforce'
    AND A.COUNTRY_NAME IN ('Ireland', 'UK')
GROUP BY
    1, 2, 3, 4, 5
ORDER BY
    1 DESC, 2;

--- MAIN QUERY
    SELECT
        LS.COUNTRY_NAME,
        LS.onboarding_area,
        LS.RIDER_DRN,
        SUBSTR(LS.RIDER_DRN, 18) AS UUID,
        dad.driver_id,
        CASE WHEN LS.is_substitute_account_on_admin THEN 'Yes' ELSE 'No' END AS is_substitute_account_on_admin,
        CASE WHEN IFNULL(OP.IS_RETURNER, FALSE) THEN 'Yes' ELSE 'No' END AS is_returner,
        TO_CHAR(TO_DATE(CASE WHEN LS.LIFECYCLE_MAIN_STAGE = 'application' AND LS.STAGE_STATUS ILIKE '%completed%' THEN GREATEST(LS.EVENT_UPDATED_AT, LS.EVENT_CREATED_AT) END), 'YYYY-MM-DD') AS onboarding_at_date,
        TO_CHAR(TO_DATE(LS.CREATED_IN_RIDER_ADMIN_AT), 'YYYY-MM-DD') AS created_in_rider_admin_at_date,
        dad.rider_admin_status_note,
        dad.CUR_ADMIN_STATUS
    FROM "RIDERS"."RIDER_LIFECYCLE_LATEST_STATUS" AS LS
    LEFT JOIN "RIDERS"."RIDER_LIFECYCLE_LATEST_ONBOARDING_PHASE" AS OP 
        ON (CASE WHEN 'yes' = 'yes' THEN LS.RIDER_DRN ELSE MD5(LS.RIDER_DRN) END) = (CASE WHEN 'yes' = 'yes' THEN OP.RIDER_DRN ELSE MD5(OP.RIDER_DRN) END)
        AND LS.LIFECYCLE_MAIN_STAGE = OP.LIFECYCLE_STAGE
    LEFT JOIN production.denormalised.driver_accounting_daily AS dad ON dad.driver_uuid = SUBSTR(LS.RIDER_DRN, 18)
    WHERE 
        CASE WHEN LS.LIFECYCLE_MAIN_STAGE = 'application' AND LS.STAGE_STATUS ILIKE '%completed%' THEN GREATEST(LS.EVENT_UPDATED_AT, LS.EVENT_CREATED_AT) END >= DATEADD('day', -7, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
        AND CASE WHEN LS.LIFECYCLE_MAIN_STAGE = 'application' AND LS.STAGE_STATUS ILIKE '%completed%' THEN GREATEST(LS.EVENT_UPDATED_AT, LS.EVENT_CREATED_AT) END < DATEADD('day', 7, DATEADD('day', -7, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))))
        AND LS.ONBOARDING_PLATFORM = 'salesforce'
        AND LS.COUNTRY_NAME IN ('Ireland', 'UK')
        AND dad.DATE >= TO_DATE(DATEADD('day', -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
        AND dad.DATE < TO_DATE(DATEADD('day', 1, DATEADD('day', -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))))
    GROUP BY
        TO_DATE(LS.CREATED_IN_RIDER_ADMIN_AT),
        TO_DATE(CASE WHEN LS.LIFECYCLE_MAIN_STAGE = 'application' AND LS.STAGE_STATUS ILIKE '%completed%' THEN GREATEST(LS.EVENT_UPDATED_AT, LS.EVENT_CREATED_AT) END),
        LS.COUNTRY_NAME,
        LS.onboarding_area,
        LS.rider_drn,
        UUID,
        is_substitute_account_on_admin,
        is_returner,
        dad.rider_admin_status_note,
        dad.CUR_ADMIN_STATUS,
        dad.driver_id
    ORDER BY
        LS.COUNTRY_NAME DESC,
        LS.onboarding_area;

SELECT
    dad.rider_admin_status_note,
    dad.CUR_ADMIN_STATUS,
    dad.driver_uuid
FROM production.denormalised.driver_accounting_daily AS dad
WHERE (CASE WHEN 'yes' = 'yes'
      THEN CAST(dad.DRIVER_UUID AS STRING) ELSE CAST(MD5(dad.DRIVER_UUID) AS STRING) END) IN ('2f903227-aed8-4136-a536-c4c8019847e7', '43923f86-7e22-43aa-8f15-79024bf66d42', '69b9d22f-eeb6-4b34-9655-31d59edd8e47', '76a67e7f-54e4-41a2-84cf-3768dca0586f', '7a72ff7d-76fc-41b3-a54a-9bc5fc77e807', 'f2d2c0e5-6b8f-480c-b5a5-0bf119a8d345')
  AND dad.DATE >= TO_DATE(DATEADD('day', -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
  AND dad.DATE < TO_DATE(DATEADD('day', 1, DATEADD('day', -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))))
GROUP BY
    dad.rider_admin_status_note,
    dad.CUR_ADMIN_STATUS,
    driver_uuid
ORDER BY
    dad.rider_admin_status_note;



SELECT DRIVER_ID, 
       CUR_ZONE, 
       MOST_COMMON_ZONE_CODE_HRS_WORKED
FROM production.denormalised.driver_accounting_daily
WHERE CUR_CITY = 'London'
LIMIT 100
;