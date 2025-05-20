
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
WHERE (DATE) = (TO_DATE(TO_TIMESTAMP('2024-05-27'))) 
AND (CUR_CITY) IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND ((CUR_ADMIN_STATUS) <> 'TERMINATED' AND (CUR_ADMIN_STATUS) <> 'PENDING' AND (CUR_ADMIN_STATUS) <> 'AWOL' AND (CUR_ADMIN_STATUS) <> 'LEFT' AND (CUR_ADMIN_STATUS) <> 'DISABLED' OR (CUR_ADMIN_STATUS) IS NULL) 
AND driver_id IN (
    SELECT DISTINCT driver_id
    FROM production.denormalised.driver_accounting_daily
    WHERE CUR_COUNTRY = 'UK'
    AND DATE BETWEEN '2024-04-22' AND '2024-05-27'
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
WHERE (DATE) = (TO_DATE(TO_TIMESTAMP('2024-06-03'))) 
AND (CUR_CITY) IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND ((CUR_ADMIN_STATUS) <> 'TERMINATED' AND (CUR_ADMIN_STATUS) <> 'PENDING' AND (CUR_ADMIN_STATUS) <> 'AWOL' AND (CUR_ADMIN_STATUS) <> 'LEFT' AND (CUR_ADMIN_STATUS) <> 'DISABLED' OR (CUR_ADMIN_STATUS) IS NULL) 
AND driver_id IN (
    SELECT DISTINCT driver_id
    FROM production.denormalised.driver_accounting_daily
    WHERE CUR_COUNTRY = 'UK'
    AND DATE BETWEEN '2024-04-29' AND '2024-06-03'
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
WHERE (DATE) = (TO_DATE(TO_TIMESTAMP('2024-06-10'))) 
AND (CUR_CITY) IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND ((CUR_ADMIN_STATUS) <> 'TERMINATED' AND (CUR_ADMIN_STATUS) <> 'PENDING' AND (CUR_ADMIN_STATUS) <> 'AWOL' AND (CUR_ADMIN_STATUS) <> 'LEFT' AND (CUR_ADMIN_STATUS) <> 'DISABLED' OR (CUR_ADMIN_STATUS) IS NULL) 
AND driver_id IN (
    SELECT DISTINCT driver_id
    FROM production.denormalised.driver_accounting_daily
    WHERE CUR_COUNTRY = 'UK'
    AND DATE BETWEEN '2024-05-06' AND '2024-06-10'
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
    COALESCE(SUM(HOURS_WORKED_PEAK_DINNER), 0) AS "Peak Hours",
    COALESCE(SUM(CNT_PEAK_DINNER_ORDERS), 0) AS "Peak Orders"
FROM production.denormalised.driver_accounting_daily
WHERE DATE IN ('2024-06-12', '2024-06-14')
AND (CUR_CITY) IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND ((CUR_ADMIN_STATUS) <> 'TERMINATED' AND (CUR_ADMIN_STATUS) <> 'PENDING' AND (CUR_ADMIN_STATUS) <> 'AWOL' AND (CUR_ADMIN_STATUS) <> 'LEFT' AND (CUR_ADMIN_STATUS) <> 'DISABLED' OR (CUR_ADMIN_STATUS) IS NULL) 
AND driver_id IN (
    SELECT DISTINCT driver_id
    FROM production.denormalised.driver_accounting_daily
    WHERE CUR_COUNTRY = 'UK'
    AND DATE BETWEEN '2024-05-08' AND '2024-06-12'
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
    COALESCE(SUM(HOURS_WORKED_PEAK_DINNER), 0) AS "Peak Hours",
    COALESCE(SUM(CNT_PEAK_DINNER_ORDERS), 0) AS "Peak Orders"
FROM production.denormalised.driver_accounting_daily
WHERE DATE IN ('2024-06-05', '2024-06-07')
AND (CUR_CITY) IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND ((CUR_ADMIN_STATUS) <> 'TERMINATED' AND (CUR_ADMIN_STATUS) <> 'PENDING' AND (CUR_ADMIN_STATUS) <> 'AWOL' AND (CUR_ADMIN_STATUS) <> 'LEFT' AND (CUR_ADMIN_STATUS) <> 'DISABLED' OR (CUR_ADMIN_STATUS) IS NULL) 
AND driver_id IN (
    SELECT DISTINCT driver_id
    FROM production.denormalised.driver_accounting_daily
    WHERE CUR_COUNTRY = 'UK'
    AND DATE BETWEEN '2024-05-01' AND '2024-06-05'
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
    COALESCE(SUM(HOURS_WORKED_PEAK_DINNER), 0) AS "Peak Hours",
    COALESCE(SUM(CNT_PEAK_DINNER_ORDERS), 0) AS "Peak Orders"
FROM production.denormalised.driver_accounting_daily
WHERE DATE IN ('2024-05-29', '2024-05-31')
AND (CUR_CITY) IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND ((CUR_ADMIN_STATUS) <> 'TERMINATED' AND (CUR_ADMIN_STATUS) <> 'PENDING' AND (CUR_ADMIN_STATUS) <> 'AWOL' AND (CUR_ADMIN_STATUS) <> 'LEFT' AND (CUR_ADMIN_STATUS) <> 'DISABLED' OR (CUR_ADMIN_STATUS) IS NULL) 
AND driver_id IN (
    SELECT DISTINCT driver_id
    FROM production.denormalised.driver_accounting_daily
    WHERE CUR_COUNTRY = 'UK'
    AND DATE BETWEEN '2024-04-24' AND '2024-05-29'
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
