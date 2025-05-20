WITH CTE1 AS (
SELECT
    driver_id,
    driver_uuid,
    cur_zone AS ZONE_NAME,
    SUM(ORDERS_DELIVERED) AS Delivered,
    COUNT(DISTINCT CASE WHEN ORDERS_DELIVERED > 0 THEN ( CASE WHEN 'yes' = 'yes'
      THEN CAST(driver_id AS STRING) ELSE CAST(MD5(driver_id) AS STRING) END  ) END ) AS "Have delivered",
    COUNT(DISTINCT ( CASE WHEN 'yes' = 'yes'
      THEN CAST(driver_id AS STRING) ELSE CAST(MD5(driver_id) AS STRING) END )) AS "Have worked"
FROM production.denormalised.driver_accounting_daily
WHERE 
 (DATE) >= DATEADD('day', -28, CURRENT_DATE())
AND (days_since_last_worked ) <= 28 

AND (CUR_COUNTRY ) IN ('Ireland', 'UK') 
AND CUR_ZONE IN 
    ('ABR', 'BCLV', 'CHE', 'CHES', 'CHNW', 'CHRC', 'STAV', 'BGH', 'HWH', 'BNC', 'BNCH', 'CDN', 'HPBN', 'PHN', 'SRH', 'STDN', 'BOR', 'CHS', 'BOU', 'BRME', 'BROA', 'CANF', 'EVER', 'HUR', 'NWM', 'OBOU', 'POO', 'BRP', 'DCE', 'DCW', 'DUR', 'DURU', 'LTL', 'MDWF', 'RAIN', 'SCR', 'SHER', 'SHIN', 'BSE', 'BTH', 'BTHE', 'BTHN', 'BTHS', 'BTHW', 'CHRL', 'BXS', 'HAST', 'CAM', 'CAMNE', 'CAMS', 'CAMW', 'HPCM', 'CHN', 'CLM', 'DNB', 'MGTG', 'SCLM', 'WALT', 'CIR', 'CLC', 'DEA', 'DOC', 'DOR', 'REI', 'ELY', 'EOXF', 'NOXF', 'OXF', 'SOXF', 'WOXF', 'EST', 'EXE', 'EXEE', 'EXES', 'EXEW', 'TSHM', 'FLM', 'GGDP', 'OTF', 'SEV', 'WRSW', 'HAR', 'KLG', 'KNB', 'HDT', 'PEM', 'RTW', 'TON', 'HER', 'HND', 'SOU', 'SOUE', 'SOUW', 'HOO', 'KYHM', 'PLST', 'PLTN', 'PLY', 'PLYN', 'SASH', 'HSL', 'MRG', 'RMG', 'NWB', 'RSH', 'WELL', 'SAN', 'SAU', 'SUA', 'TRU')

GROUP BY 1, 2, 3
),

CTE2 AS (
SELECT
    driver_id,
    driver_uuid,
    MOST_COMMON_ZONE_CODE_HRS_WORKED_3WKS AS ZONE_NAME,
    SUM(ORDERS_DELIVERED) AS Delivered,
    COUNT(DISTINCT CASE WHEN ORDERS_DELIVERED > 0 THEN ( CASE WHEN 'yes' = 'yes'
      THEN CAST(driver_id AS STRING) ELSE CAST(MD5(driver_id) AS STRING) END  ) END ) AS "Have delivered",
    COUNT(DISTINCT ( CASE WHEN 'yes' = 'yes'
      THEN CAST(driver_id AS STRING) ELSE CAST(MD5(driver_id) AS STRING) END )) AS "Have worked"
FROM production.denormalised.driver_accounting_daily
WHERE 
 (DATE) >= DATEADD('day', -28, CURRENT_DATE())
AND (days_since_last_worked ) <= 28 
AND (CUR_COUNTRY ) IN ('Ireland', 'UK') 
AND MOST_COMMON_ZONE_CODE_HRS_WORKED_3WKS IN 
    ('ABR', 'BCLV', 'CHE', 'CHES', 'CHNW', 'CHRC', 'STAV', 'BGH', 'HWH', 'BNC', 'BNCH', 'CDN', 'HPBN', 'PHN', 'SRH', 'STDN', 'BOR', 'CHS', 'BOU', 'BRME', 'BROA', 'CANF', 'EVER', 'HUR', 'NWM', 'OBOU', 'POO', 'BRP', 'DCE', 'DCW', 'DUR', 'DURU', 'LTL', 'MDWF', 'RAIN', 'SCR', 'SHER', 'SHIN', 'BSE', 'BTH', 'BTHE', 'BTHN', 'BTHS', 'BTHW', 'CHRL', 'BXS', 'HAST', 'CAM', 'CAMNE', 'CAMS', 'CAMW', 'HPCM', 'CHN', 'CLM', 'DNB', 'MGTG', 'SCLM', 'WALT', 'CIR', 'CLC', 'DEA', 'DOC', 'DOR', 'REI', 'ELY', 'EOXF', 'NOXF', 'OXF', 'SOXF', 'WOXF', 'EST', 'EXE', 'EXEE', 'EXES', 'EXEW', 'TSHM', 'FLM', 'GGDP', 'OTF', 'SEV', 'WRSW', 'HAR', 'KLG', 'KNB', 'HDT', 'PEM', 'RTW', 'TON', 'HER', 'HND', 'SOU', 'SOUE', 'SOUW', 'HOO', 'KYHM', 'PLST', 'PLTN', 'PLY', 'PLYN', 'SASH', 'HSL', 'MRG', 'RMG', 'NWB', 'RSH', 'WELL', 'SAN', 'SAU', 'SUA', 'TRU')
GROUP BY 1, 2, 3
),
CTE3 AS(
SELECT DRIVER_ID, DRIVER_UUID, ZONE_NAME, Delivered
FROM CTE1
UNION ALL 
SELECT DRIVER_ID, DRIVER_UUID, ZONE_NAME, Delivered
FROM CTE2
)

SELECT DRIVER_ID, DRIVER_UUID, ZONE_NAME, COALESCE(SUM(Delivered), 0) AS Delivered FROM CTE3
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC NULLS LAST, 3




;