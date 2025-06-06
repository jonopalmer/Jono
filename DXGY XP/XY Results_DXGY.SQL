SELECT 
  DRIVER_ID,
  COUNT(STATUS) ORDER_COUNT,
  DATE(LOCAL_TIME_OA_CREATED_AT) AS "XP_DATE",
  CITY_NAME AS "City", COUNTRY_NAME AS "Country",
CASE 
    WHEN DAYOFWEEK(LOCAL_TIME_OA_CREATED_AT) = 1 
        AND EXTRACT(HOUR FROM LOCAL_TIME_OA_CREATED_AT) BETWEEN 12 AND 14
    THEN 'Monday Lunch'
    WHEN DAYOFWEEK(LOCAL_TIME_OA_CREATED_AT) = 3 
        AND EXTRACT(HOUR FROM LOCAL_TIME_OA_CREATED_AT) BETWEEN 18 AND 21
    THEN 'Wednesday Dinner'
    WHEN DAYOFWEEK(LOCAL_TIME_OA_CREATED_AT) = 5 
        AND EXTRACT(HOUR FROM LOCAL_TIME_OA_CREATED_AT) BETWEEN 18 AND 21
    THEN 'Friday SP' ELSE NULL
END AS Period
FROM PRODUCTION.denormalised.orders 
  WHERE COUNTRY_NAME IN ('UK', 'Ireland')
  AND CITY_NAME IN ('Aberystwyth', 'Bath', 'Cambridge', 'Chelmsford', 'Cirencester', 'Deal', 'Harrogate', 'Haywards Heath', 'Hereford', 'Newbury', 'Sevenoaks', 'Southampton')
  AND STATUS = 'DELIVERED'  
  AND (
    (LOCAL_TIME_OA_CREATED_AT BETWEEN TO_TIMESTAMP('2024-08-19 12:00') AND TO_TIMESTAMP('2024-08-19 14:00')) OR
    (LOCAL_TIME_OA_CREATED_AT BETWEEN TO_TIMESTAMP('2024-08-21 18:00') AND TO_TIMESTAMP('2024-08-21 21:00')) OR
    (LOCAL_TIME_OA_CREATED_AT BETWEEN TO_TIMESTAMP('2024-08-23 18:00') AND TO_TIMESTAMP('2024-08-23 21:00')))
  AND DRIVER_ID IS NOT NULL
GROUP BY 
  DRIVER_ID, CITY_NAME, COUNTRY_NAME, PERIOD, XP_DATE    
ORDER BY 
  CITY_NAME, DRIVER_ID, XP_DATE
; 