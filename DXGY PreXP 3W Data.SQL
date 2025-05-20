
SELECT
    CASE WHEN 'yes' = 'yes'
      THEN CAST(driver_id AS STRING) ELSE CAST(MD5(driver_id) AS STRING) END  AS "Driver ID",
    (TO_CHAR(TO_DATE(DATE), 'YYYY-MM-DD')) AS "Date",
    CUR_CITY  AS "City Name",
    COALESCE(SUM(HOURS_WORKED_PEAK_LUNCH), 0) AS "Peak Hours",
    COALESCE(SUM(CNT_PEAK_LUNCH_ORDERS), 0) AS "Peak Orders",
    --COALESCE(SUM(HOURS_WORKED_PEAK_DINNER), 0) AS "Peak Hours",
    --COALESCE(SUM(CNT_PEAK_DINNER_ORDERS), 0) AS "Peak Orders"
FROM production.denormalised.driver_accounting_daily
WHERE (DATE) = (TO_DATE(TO_TIMESTAMP('2024-06-17'))) 
AND (CUR_CITY) IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND ((CUR_ADMIN_STATUS) <> 'TERMINATED' AND (CUR_ADMIN_STATUS) <> 'PENDING' AND (CUR_ADMIN_STATUS) <> 'AWOL' AND (CUR_ADMIN_STATUS) <> 'LEFT' AND (CUR_ADMIN_STATUS) <> 'DISABLED' OR (CUR_ADMIN_STATUS) IS NULL) 
AND driver_id IN (
    SELECT DISTINCT driver_id
    FROM production.denormalised.driver_accounting_daily
    WHERE CUR_COUNTRY = 'UK'
    AND DATE BETWEEN '2024-05-13' AND '2024-06-17'
    GROUP BY driver_id
    HAVING SUM(ORDERS_DELIVERED) > 0
)
GROUP BY
    (TO_DATE(DATE)),
    (TO_DATE(LAST_WORK_DATE)),
    driver_id,
    CUR_CITY

UNION ALL


 SELECT
    CASE WHEN 'yes' = 'yes'
      THEN CAST(driver_id AS STRING) ELSE CAST(MD5(driver_id) AS STRING) END  AS "Driver ID",
    (TO_CHAR(TO_DATE(DATE), 'YYYY-MM-DD')) AS "Date",
    CUR_CITY  AS "City Name",
    COALESCE(SUM(HOURS_WORKED_PEAK_LUNCH), 0) AS "Peak Hours",
    COALESCE(SUM(CNT_PEAK_LUNCH_ORDERS), 0) AS "Peak Orders",
    --COALESCE(SUM(HOURS_WORKED_PEAK_DINNER), 0) AS "Peak Hours",
    --COALESCE(SUM(CNT_PEAK_DINNER_ORDERS), 0) AS "Peak Orders"
FROM production.denormalised.driver_accounting_daily
WHERE (DATE) = (TO_DATE(TO_TIMESTAMP('2024-06-24'))) 
AND (CUR_CITY) IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND ((CUR_ADMIN_STATUS) <> 'TERMINATED' AND (CUR_ADMIN_STATUS) <> 'PENDING' AND (CUR_ADMIN_STATUS) <> 'AWOL' AND (CUR_ADMIN_STATUS) <> 'LEFT' AND (CUR_ADMIN_STATUS) <> 'DISABLED' OR (CUR_ADMIN_STATUS) IS NULL) 
AND driver_id IN (
    SELECT DISTINCT driver_id
    FROM production.denormalised.driver_accounting_daily
    WHERE CUR_COUNTRY = 'UK'
    AND DATE BETWEEN '2024-05-20' AND '2024-06-24'
    GROUP BY driver_id
    HAVING SUM(ORDERS_DELIVERED) > 0
)
GROUP BY
    (TO_DATE(DATE)),
    (TO_DATE(LAST_WORK_DATE)),
    driver_id,
    CUR_CITY
ORDER BY
    2, 3, 1;   
