    --- DXGY Mobilisation -- recently onboarded riders
    SELECT
        ORDER_1_OB_city,
        CREATED_IN_RIDER_ADMIN_AT,
        CITY,
        driver_id,
        RIDER_UUID
    FROM (
        SELECT
            IFNULL(CASE WHEN b.FIRST_ORDER_DATE IS NOT NULL THEN 1 ELSE 0 END, 0) AS ORDER_1_OB_city,
            CREATED_IN_RIDER_ADMIN_AT, a.CITY, b.driver_id, a.RIDER_UUID,
            ROW_NUMBER() OVER (PARTITION BY b.driver_id ORDER BY CREATED_IN_RIDER_ADMIN_AT ASC, a.CITY) AS rn
        FROM PRODUCTION.RIDERS.RIDER_LIFECYCLE_LATEST_STATUS AS a
        LEFT JOIN production.denormalised.driver_accounting_daily AS b 
            ON CAST(a.RIDER_UUID AS STRING) = CAST(b.DRIVER_UUID AS STRING)
        WHERE ONBOARDING_PLATFORM = 'salesforce'
          AND LIFECYCLE_MAIN_STAGE = 'application'
          AND IS_SUBSTITUTE_ACCOUNT_ON_ADMIN = 'FALSE'
          AND a.COUNTRY_NAME IN ('UK', 'Ireland')
          AND IS_CREATED_ON_ADMIN = 'TRUE'
          AND TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) >= '2024-08-01'
          AND DATE = (SELECT MAX(DATE) FROM production.denormalised.driver_accounting_daily)
          AND CITY IN ('St Andrews', 'Dundee', 'Perth', 'Sevenoaks', 'Guildford', 'Godalming', 'Winchester', 'Eastleigh', 'Camberley', 'Aldershot', 'Farnborough','Bracknell','Wokingham','Maidstone','Southampton','Hedge End')
    ) subquery
    WHERE rn = 1
    ORDER BY CREATED_IN_RIDER_ADMIN_AT DESC, CITY