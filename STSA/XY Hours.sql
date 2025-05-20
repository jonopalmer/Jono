
SELECT 
  DRIVER_ID, CITY_NAME,  DATE,
    CASE 
		WHEN DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 1  THEN 'Mon Lunch'
		WHEN DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 3  THEN 'Wed Dinner'
		WHEN DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 5  THEN 'Fri Dinner'
	END AS PEAK,
  CASE 
		WHEN DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 1  THEN SUM(HRS_WORKED_PEAK_LUNCH) 
		WHEN DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 3  THEN SUM(HRS_WORKED_PEAK_DINNER)
		WHEN DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 5  THEN SUM(HRS_WORKED_PEAK_DINNER)
	END AS PEAK_HOURS,
	SUM(HOURS_WORKED_ADJUSTED) AS ALL_HOURS
  
FROM PRODUCTION.DENORMALISED.DRIVER_HOURS_WORKED

WHERE CITY_NAME IN 
	('Bath', 'Chelmsford', 'Cambridge', 'Southampton', 'Royal Tunbridge Wells', 'Colchester', 'Brighton', 'Bournemouth', 'Exeter', 'Cheltenham', 'Oxford', 'Plymouth', 'Harrogate', 'Newbury', 'Hereford', 'Haywards Heath', 'Durham', 'Bury St Edmunds', 'Rushden', 'Eastbourne', 'Reigate', 'Chichester', 'Margate', 'Hastings', 'Deal', 'Sevenoaks', 'Aberystwyth', 'Cirencester', 'Dorchester', 'St Andrews', 'Ely', 'Falmouth', 'Haslemere', 'Truro', 'Stratford upon Avon', 'Saint Austell')
	AND	(DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 1 OR DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 3 OR DAYOFWEEK(ADJUSTED_CLOCK_IN_LOCAL) = 5)
	AND DATE >= '2024-06-17'
GROUP BY 
  DRIVER_ID, CITY_NAME, DATE, ADJUSTED_CLOCK_IN_LOCAL
ORDER BY 
  CITY_NAME, DRIVER_ID, DATE

;
