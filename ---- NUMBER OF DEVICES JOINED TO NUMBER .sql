---- NUMBER OF DEVICES JOINED TO NUMBER CHANGES --- 3 NUMBERS & 3 DEVICES
WITH CTE AS (
SELECT rec:model AS device, rec:rider_id::number AS rider_id, rec_updated_at::date AS last_update
FROM production.core.rider_devices
WHERE Rider_ID IN (
SELECT driver_id FROM PRODUCTION.DENORMALISED.DRIVER_ACCOUNTING_DAILY WHERE CUR_COUNTRY IN ('Ireland')
) AND last_update >= '2025-01-23'
)
, CTE2 AS(
SELECT DRIVER_ID,
ROUND(COALESCE(SUM(HOURS_WORKED), 0)) AS hours,
--COALESCE(SUM(phone_number_changes),0) AS number_changes
FROM production.denormalised.driver_accounting_daily
WHERE date >= '2025-01-23'
AND CUR_COUNTRY IN ('Ireland', 'UK')
AND application_approved_date >= '2025-01-23'
GROUP BY
DRIVER_ID
--HAVING number_changes >= 1
)

SELECT cur_city, COUNT(DISTINCT device) AS devices, hours, COUNT(DISTINCT RIDER_ID) AS number_riders
FROM CTE a
LEFT JOIN PRODUCTION.DENORMALISED.DRIVER_ACCOUNTING_DAILY b ON a.rider_id = b.driver_id
INNER JOIN CTE2 c ON a.rider_id = c.driver_id
WHERE b.date = (
SELECT MAX(date) FROM PRODUCTION.DENORMALISED.DRIVER_ACCOUNTING_DAILY
)
GROUP BY cur_city, hours
HAVING devices >= 1
ORDER BY cur_city DESC, devices DESC
;
