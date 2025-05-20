
--- make for zone lists and compare to city list
-- check accuracy of cur status is null necessary
SELECT
    dad.CUR_ZONE  AS zone,
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
    and dad.cur_zone in ('ABR', 'BCLV', 'CHE', 'CHES', 'CHNW', 'CHRC', 'STAV', 'BGH', 'HWH', 'BNC', 'BNCH', 'CDN', 'HPBN', 'PHN', 'SRH', 'STDN', 'BOR', 'CHS', 'BOU', 'BRME', 'BROA', 'CANF', 'EVER', 'HUR', 'NWM', 'OBOU', 'POO', 'BRP', 'DCE', 'DCW', 'DUR', 'DURU', 'LTL', 'MDWF', 'RAIN', 'SCR', 'SHER', 'SHIN', 'BSE', 'BTH', 'BTHE', 'BTHN', 'BTHS', 'BTHW', 'CHRL', 'BXS', 'HAST', 'CAM', 'CAMNE', 'CAMS', 'CAMW', 'HPCM', 'CHN', 'CLM', 'DNB', 'MGTG', 'SCLM', 'WALT', 'CIR', 'CLC', 'DEA', 'DOC', 'DOR', 'REI', 'ELY', 'EOXF', 'NOXF', 'OXF', 'SOXF', 'WOXF', 'EST', 'EXE', 'EXEE', 'EXES', 'EXEW', 'TSHM', 'FLM', 'GGDP', 'OTF', 'SEV', 'WRSW', 'HAR', 'KLG', 'KNB', 'HDT', 'PEM', 'RTW', 'TON', 'HER', 'HND', 'SOU', 'SOUE', 'SOUW', 'HOO', 'KYHM', 'PLST', 'PLTN', 'PLY', 'PLYN', 'SASH', 'HSL', 'MRG', 'RMG', 'NWB', 'RSH', 'WELL', 'SAN', 'SAU', 'SUA', 'TRU')
    and r.status not in ('TERMINATED','AWOL','LEFT')
    and r.status is not null
QUALIFY ROW_NUMBER() OVER(PARTITION BY dad.DRIVER_UUID ORDER BY dad.date  DESC) = 1
ORDER BY RIDER_ID

;