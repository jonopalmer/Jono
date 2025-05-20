--- accurate onboarding city

----------------------------------------------------------------------------------------------------
SELECT
    onboarding_area,
    RIDER_UUID,
    TO_CHAR(
        TO_DATE(
            CASE 
                WHEN LIFECYCLE_MAIN_STAGE = 'application' 
                AND STAGE_STATUS ILIKE '%completed%' 
                THEN greatest(EVENT_UPDATED_AT, EVENT_CREATED_AT)
            END), 'YYYY-MM-DD') AS onboarding_at_date

FROM RIDERS.RIDER_LIFECYCLE_LATEST_STATUS
WHERE 
    greatest(EVENT_UPDATED_AT, EVENT_CREATED_AT) >= DATEADD('day', -7, DATE_TRUNC('week', CURRENT_TIMESTAMP()))
    AND greatest(EVENT_UPDATED_AT, EVENT_CREATED_AT) < DATE_TRUNC('week', CURRENT_TIMESTAMP())
    AND LIFECYCLE_MAIN_STAGE = 'application'
    AND ONBOARDING_PLATFORM = 'salesforce'
    AND COUNTRY_NAME IN ('Ireland', 'UK')
    AND (NOT is_substitute_account_on_admin OR is_substitute_account_on_admin IS NULL)
GROUP BY 
    onboarding_area,
    RIDER_UUID,
    TO_DATE(
        CASE 
            WHEN LIFECYCLE_MAIN_STAGE = 'application' 
            AND STAGE_STATUS ILIKE '%completed%' 
            THEN greatest(EVENT_UPDATED_AT, EVENT_CREATED_AT)
        END
    )
HAVING COUNT(DISTINCT CASE 
    WHEN LIFECYCLE_MAIN_STAGE = 'application' 
    AND STAGE_STATUS ILIKE '%completed%'
    THEN RIDER_UUID 
END) >= 1
ORDER BY 
    onboarding_area, 3, 2
    
    ;