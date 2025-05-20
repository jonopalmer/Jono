SELECT
    dad.CUR_CITY  AS city,
    dad.driver_id as rider_id,
    dad.DRIVER_UUID as rider_uuid
FROM production.denormalised.driver_accounting_daily AS dad
left join production.denormalised.denormalised_driver as r on dad.driver_id=r.id
WHERE 
    dad.DATE >= DATEADD(day, -28, date_trunc(week,current_timestamp))
    --and dad.CUR_CITY  IN ('Aix en Provence', 'Amiens', 'Annecy', 'Beauvais', 'Bordeaux', 'Caen', 'Clermont-Ferrand', 'Dijon', 'Guingamp', 'Lille', 'Montpellier', 'Nice', 'Perpignan', 'Rennes', 'Rumilly')
    AND (
        dad.CUR_ADMIN_STATUS not in('TERMINATED','AWOL','LEFT','DISABLED') 
        OR dad.CUR_ADMIN_STATUS IS NULL
        )
    AND dad.ACQ_COUNTRY IN ('France', 'Paris', 'RFR')
    and r.status not in ('TERMINATED','AWOL','LEFT')
    and r.status is not null
QUALIFY ROW_NUMBER() OVER(PARTITION BY dad.DRIVER_UUID ORDER BY dad.date  DESC) = 1
;

SELECT
    dad.CUR_CITY  AS city,
    dad.driver_id as rider_id,
    dad.DRIVER_UUID as rider_uuid
FROM production.denormalised.driver_accounting_daily AS dad
left join production.denormalised.denormalised_driver as r on dad.driver_id=r.id
WHERE 
    dad.DATE >= DATEADD(day, -28, date_trunc(week,current_timestamp))
    --and dad.CUR_CITY  IN ('Aix en Provence', 'Amiens', 'Annecy', 'Beauvais', 'Bordeaux', 'Caen', 'Clermont-Ferrand', 'Dijon', 'Guingamp', 'Lille', 'Montpellier', 'Nice', 'Perpignan', 'Rennes', 'Rumilly')
    AND (
        dad.CUR_ADMIN_STATUS not in('TERMINATED','AWOL','LEFT','DISABLED') 
        OR dad.CUR_ADMIN_STATUS IS NULL
        )
    AND dad.ACQ_COUNTRY IN ('France', 'Paris', 'RFR')
    and r.status not in ('TERMINATED','AWOL','LEFT')
    and r.status is not null
QUALIFY ROW_NUMBER() OVER(PARTITION BY dad.DRIVER_UUID ORDER BY dad.date  DESC) = 1
;