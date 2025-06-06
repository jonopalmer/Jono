SELECT A.ZONE_CODE, B.CLUSTER_NAME, A.ONBOARDING_AREA, A.CITY_NAME, SUM(B.ORDERS_DELIVERED) AS ORDERS_DELIVERED_1W

FROM SCRATCH.RIDERS.ZONE_DRN_ID_TO_ONBOARDING_AREA A
LEFT JOIN PRODUCTION.AGGREGATE.ZONE_DELIVERY_METRICS_HOURLY B ON A.ZONE_CODE = B.ZONE_CODE


WHERE A.COUNTRY_NAME IN ('UK', 'Ireland')
    AND B.START_OF_PERIOD_LOCAL >= DATEADD(DAY, -7, CURRENT_DATE)

GROUP BY A.ZONE_CODE, A.ONBOARDING_AREA, A.CITY_NAME, B.CLUSTER_NAME
HAVING ORDERS_DELIVERED_1W > 0
    
ORDER BY A.CITY_NAME, A.ONBOARDING_AREA, ORDERS_DELIVERED_1W DESC