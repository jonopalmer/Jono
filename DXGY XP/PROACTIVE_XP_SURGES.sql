

SELECT CAMPAIGN_START_AT_LOCAL, CAMPAIGN_END_AT_LOCAL, AMOUNT_MULTIPLIER, ZONE_CODE, CITY_NAME, DATE(CAMPAIGN_START_AT_LOCAL) DATE, CAMPAIGN_DRN_ID, CAMPAIGN_AMOUNT_LOCAL_SUM, CNT_ORDERS


FROM PRODUCTION.DENORMALISED.CAMPAIGN_MANAGER 

WHERE CITY_NAME IN ('Fife & Perthshire', 'Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND CAMPAIGN_START_AT_LOCAL >= '2024-07-22'
AND CAMPAIGN_END_AT_LOCAL <= '2024-08-20'
AND DAYOFWEEK(CAMPAIGN_START_AT_LOCAL) = 1
AND EXTRACT(HOUR FROM CAMPAIGN_START_AT_LOCAL) = 12
AND EXTRACT(MINUTE FROM CAMPAIGN_START_AT_LOCAL) = 0
AND EXTRACT(SECOND FROM CAMPAIGN_START_AT_LOCAL) = 0
AND EXTRACT(HOUR FROM CAMPAIGN_END_AT_LOCAL) = 14
--AND AMOUNT_MULTIPLIER = 1.2

UNION ALL 

SELECT CAMPAIGN_START_AT_LOCAL, CAMPAIGN_END_AT_LOCAL, AMOUNT_MULTIPLIER, ZONE_CODE, CITY_NAME, DATE(CAMPAIGN_START_AT_LOCAL) DATE, CAMPAIGN_DRN_ID, CAMPAIGN_AMOUNT_LOCAL_SUM, CNT_ORDERS

FROM PRODUCTION.DENORMALISED.CAMPAIGN_MANAGER 

WHERE CITY_NAME IN ('Fife & Perthshire', 'Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND CAMPAIGN_START_AT_LOCAL >= '2024-07-24'
AND CAMPAIGN_END_AT_LOCAL <= '2024-08-24'
AND (DAYOFWEEK(CAMPAIGN_START_AT_LOCAL) = 3 OR DAYOFWEEK(CAMPAIGN_START_AT_LOCAL) = 5)
AND EXTRACT(HOUR FROM CAMPAIGN_START_AT_LOCAL) = 18
AND EXTRACT(MINUTE FROM CAMPAIGN_START_AT_LOCAL) = 0
AND EXTRACT(SECOND FROM CAMPAIGN_START_AT_LOCAL) = 0
AND EXTRACT(HOUR FROM CAMPAIGN_END_AT_LOCAL) = 21
--AND AMOUNT_MULTIPLIER = 1.2

ORDER BY CAMPAIGN_START_AT_LOCAL ASC, CITY_NAME ASC

;





---- CITY ONLY


SELECT CAMPAIGN_START_AT_LOCAL, CAMPAIGN_END_AT_LOCAL, AMOUNT_MULTIPLIER, CITY_NAME, DATE(CAMPAIGN_START_AT_LOCAL) DATE, SUM(CAMPAIGN_AMOUNT_LOCAL_SUM), SUM(CNT_ORDERS)


FROM PRODUCTION.DENORMALISED.CAMPAIGN_MANAGER 

WHERE CITY_NAME IN ('Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND CAMPAIGN_START_AT_LOCAL >= '2024-07-22'
AND CAMPAIGN_END_AT_LOCAL <= '2024-08-20'
AND DAYOFWEEK(CAMPAIGN_START_AT_LOCAL) = 1
AND EXTRACT(HOUR FROM CAMPAIGN_START_AT_LOCAL) = 12
AND EXTRACT(MINUTE FROM CAMPAIGN_START_AT_LOCAL) = 0
AND EXTRACT(SECOND FROM CAMPAIGN_START_AT_LOCAL) = 0
AND EXTRACT(HOUR FROM CAMPAIGN_END_AT_LOCAL) = 14
--AND AMOUNT_MULTIPLIER = 1.2
GROUP BY 1,2,3,4,5


UNION ALL 

SELECT CAMPAIGN_START_AT_LOCAL, CAMPAIGN_END_AT_LOCAL, AMOUNT_MULTIPLIER, CITY_NAME, DATE(CAMPAIGN_START_AT_LOCAL) DATE, SUM(CAMPAIGN_AMOUNT_LOCAL_SUM), SUM(CNT_ORDERS)

FROM PRODUCTION.DENORMALISED.CAMPAIGN_MANAGER 

WHERE CITY_NAME IN ('Fife & Perthshire','Aberystwyth', 'Bath', 'Bournemouth', 'Brighton', 'Bury St Edmunds', 'Cambridge', 'Chelmsford', 'Cheltenham', 'Chichester', 'Cirencester', 'Colchester', 'Deal', 'Dorchester', 'Durham', 'Eastbourne', 'Ely', 'Exeter', 'Falmouth', 'Harrogate', 'Haslemere', 'Hastings', 'Haywards Heath', 'Hereford', 'Margate', 'Newbury', 'Oxford', 'Plymouth', 'Reigate', 'Royal Tunbridge Wells', 'Rushden', 'Saint Austell', 'Sevenoaks', 'Southampton', 'St Andrews', 'Stratford upon Avon', 'Truro') 
AND CAMPAIGN_START_AT_LOCAL >= '2024-07-24'
AND CAMPAIGN_END_AT_LOCAL <= '2024-08-24'
AND (DAYOFWEEK(CAMPAIGN_START_AT_LOCAL) = 3 OR DAYOFWEEK(CAMPAIGN_START_AT_LOCAL) = 5)
AND EXTRACT(HOUR FROM CAMPAIGN_START_AT_LOCAL) = 18
AND EXTRACT(MINUTE FROM CAMPAIGN_START_AT_LOCAL) = 0
AND EXTRACT(SECOND FROM CAMPAIGN_START_AT_LOCAL) = 0
AND EXTRACT(HOUR FROM CAMPAIGN_END_AT_LOCAL) = 21
--AND AMOUNT_MULTIPLIER = 1.2
GROUP BY 1,2,3,4,5


ORDER BY CAMPAIGN_START_AT_LOCAL ASC, CITY_NAME ASC
