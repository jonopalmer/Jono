-- MOST UP TO DATE -- UPDATING CITY TO ONBOARDING AREA ----


-- NEW LEAKAGE QUERY including near/far distance and city details within clusters, exluding subs
--------------------------------------------------------------------------------------------------------------------------------------------------
----------------REFERENCES------------------------------------------------------------------------------------------------------------  
-- ===========================================================================================================================================================
-- 1.1 CITY PAIRS -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE CD_PAIRS1 AS (

        SELECT 
            DZMH.COUNTRY_NAME, 
            DZMH.CLUSTER_NAME, 
            COALESCE(OA.ONBOARDING_AREA, OA.CITY_NAME) AS ONBOARDING_AREA
        FROM production.AGGREGATE.AGG_ZONE_DELIVERY_METRICS_HOURLY AS DZMH
        LEFT JOIN scratch.riders.zone_drn_id_to_onboarding_area AS OA ON DZMH.ZONE_CODE = OA.ZONE_CODE
        WHERE DZMH.COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
            AND ONBOARDING_AREA IS NOT NULL
        GROUP BY DZMH.COUNTRY_NAME, DZMH.CLUSTER_NAME, OA.ONBOARDING_AREA, OA.CITY_NAME
        ORDER BY DZMH.COUNTRY_NAME DESC, DZMH.CLUSTER_NAME, OA.ONBOARDING_AREA
        );

CREATE OR REPLACE TEMPORARY TABLE CD_PAIRS2 AS (
        SELECT A.COUNTRY_NAME, A.ONBOARDING_AREA AS CITY1, B.ONBOARDING_AREA AS CITY2, A.ONBOARDING_AREA || ' - ' || B.ONBOARDING_AREA AS CLUSTER_PAIR
        FROM CD_PAIRS1 AS A
        LEFT JOIN CD_PAIRS1 AS B ON A.CLUSTER_NAME = B.CLUSTER_NAME
        ORDER BY A.COUNTRY_NAME DESC, A.ONBOARDING_AREA, B.ONBOARDING_AREA
        );


/*
Select * 
From scratch.riders.zone_drn_id_to_onboarding_area
Where Country_name in ('UK','Ireland','France','Italy','Belgium') 
ORDER BY country_name DESC, ONBOARDING_AREA;


SELECT * FROM CD_PAIRS1 ORDER BY COUNTRY_NAME DESC, CITY1, CITY2;

SELECT * FROM CD_PAIRS2 ORDER BY COUNTRY_NAME DESC, CITY1, CITY2;
*/

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- ===========================================================================================================================================================
-- 1.2 CITY DISTANCES -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================


CREATE OR REPLACE TEMPORARY TABLE CITY_DISTANCES AS (
        WITH city_list AS (
            SELECT
                B.ONBOARDING_AREA,
                MEDIAN(CENTROID_GEO_LAT) AS GEO_LAT, 
                MEDIAN(CENTROID_GEO_LONG) AS GEO_LONG
            FROM PRODUCTION.REFERENCE.ZONE_CITY_COUNTRY A 
            LEFT JOIN scratch.riders.zone_drn_id_to_onboarding_area B ON A.zone_code = B.ZONE_CODE
            WHERE A.COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
                AND B.ONBOARDING_AREA IS NOT NULL
            GROUP BY B.ONBOARDING_AREA
            ORDER BY B.ONBOARDING_AREA
        )
        SELECT 
            A.ONBOARDING_AREA || B.ONBOARDING_AREA AS CITY_DETAILED_COMBO,
            A.ONBOARDING_AREA AS CITY_DETAILED_1, 
            B.ONBOARDING_AREA AS CITY_DETAILED_2, 
            A.GEO_LAT AS CITY_DETAILED_1_LAT,
            A.GEO_LONG AS CITY_DETAILED_1_LONG,
            B.GEO_LAT AS CITY_DETAILED_2_LAT,
            B.GEO_LONG AS CITY_DETAILED_2_LONG,
            ROUND(haversine(A.GEO_LAT, A.GEO_LONG, B.GEO_LAT, B.GEO_LONG), 0) AS DISTANCE_KM,
            CASE WHEN ROUND(haversine(A.GEO_LAT, A.GEO_LONG, B.GEO_LAT, B.GEO_LONG), 0) > 20 THEN 'FAR'
                ELSE 'NEAR'
            END AS DISTANCE_CATEGORY 
        FROM city_list A
        CROSS JOIN city_list B
        ORDER BY CITY_DETAILED_COMBO
        )

;
 -- SELECT * FROM CITY_DISTANCES WHERE CITY_DETAILED_1 LIKE 'London%' and CITY_DETAILED_2 LIKE 'London%' order by CITY_DETAILED_1, CITY_DETAILED_2;


CREATE OR REPLACE TEMPORARY TABLE CITY_DISTANCES_CITY_NAME AS (
        WITH city_list2 AS (
            SELECT
                CITY_NAME AS CITY_NAME,
                MEDIAN(CENTROID_GEO_LAT) AS GEO_LAT, 
                MEDIAN(CENTROID_GEO_LONG) AS GEO_LONG
            FROM PRODUCTION.REFERENCE.ZONE_CITY_COUNTRY
            WHERE COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
            GROUP BY CITY_NAME
        )
        SELECT 
            A.CITY_NAME || B.CITY_NAME AS CITY_NAME_COMBO,
            A.CITY_NAME AS CITY_NAME_1, 
            B.CITY_NAME AS CITY_NAME_2, 
            A.GEO_LAT AS CITY_NAME_1_LAT,
            A.GEO_LONG AS CITY_NAME_1_LONG,
            B.GEO_LAT AS CITY_NAME_2_LAT,
            B.GEO_LONG AS CITY_NAME_2_LONG,
            ROUND(haversine(A.GEO_LAT, A.GEO_LONG, B.GEO_LAT, B.GEO_LONG), 0) AS DISTANCE_KM,
            CASE WHEN ROUND(haversine(A.GEO_LAT, A.GEO_LONG, B.GEO_LAT, B.GEO_LONG), 0) > 20 THEN 'FAR'
                ELSE 'NEAR'
            END AS DISTANCE_CATEGORY 
        FROM city_list2 A
        CROSS JOIN city_list2 B
        ORDER BY CITY_NAME_COMBO
        );
/*
SELECT * FROM CITY_DISTANCES_CITY_NAME WHERE CITY_NAME_1 = 'Paris' ORDER BY DISTANCE_KM;
*/ 



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------THE SF SIDE---------------------------------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
-- 2.0 New_Onboarding_Area_Process -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================

CREATE OR REPLACE TEMPORARY TABLE New_OA_Process AS  (
        SELECT
            onboarding_area,
            driver_id,
            TO_CHAR(
                TO_DATE(
                    CASE 
                        WHEN LIFECYCLE_MAIN_STAGE = 'application' 
                        AND STAGE_STATUS ILIKE '%completed%' 
                        THEN greatest(EVENT_UPDATED_AT, EVENT_CREATED_AT)
                    END), 'YYYY-MM-DD') AS onboarding_at_date
            , CASE WHEN COUNTRY_NAME IN ('UK', 'Ireland') THEN 'UKI' ELSE COUNTRY_NAME END AS COUNTRY_GROUP

        FROM RIDERS.RIDER_LIFECYCLE_LATEST_STATUS AS a
        LEFT JOIN production.denormalised.driver_accounting_daily AS b 
                            ON CAST(a.RIDER_UUID AS STRING) = CAST(b.DRIVER_UUID AS STRING)
        WHERE 

            TO_DATE(DATE_TRUNC('month', TO_DATE(
                CASE 
                    WHEN LIFECYCLE_MAIN_STAGE = 'application' 
                    AND STAGE_STATUS ILIKE '%completed%' 
                    THEN greatest(EVENT_UPDATED_AT, EVENT_CREATED_AT)
                END))) >= '2023-11-01'
            AND LIFECYCLE_MAIN_STAGE = 'application'
            AND ONBOARDING_PLATFORM = 'salesforce'
            AND COUNTRY_NAME IN ('Ireland', 'UK')
            AND (NOT is_substitute_account_on_admin OR is_substitute_account_on_admin IS NULL)
        GROUP BY 
            onboarding_area,
            RIDER_UUID,
            TO_DATE(
                CASE 
                    WHEN LIFECYCLE_MAIN_STAGE = 'application' 
                    AND STAGE_STATUS ILIKE '%completed%' 
                    THEN greatest(EVENT_UPDATED_AT, EVENT_CREATED_AT)
                END
            ),
            driver_id,
            COUNTRY_GROUP
        HAVING COUNT(DISTINCT CASE 
            WHEN LIFECYCLE_MAIN_STAGE = 'application' 
            AND STAGE_STATUS ILIKE '%completed%'
            THEN RIDER_UUID 
        END) >= 1
        ORDER BY 
            COUNTRY_GROUP desc, onboarding_area, 3, 2

        )


        ;



-- ===========================================================================================================================================================
-- 2.1 SF_OB_City -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================

CREATE OR REPLACE TEMPORARY TABLE SF_OB_City AS (
            SELECT
                COUNTRY_GROUP,
                approved_month,
                COALESCE(CITY, onboarding_area) AS CITY,
                driver_id,
                RIDER_UUID,
                activated_28D_OB_city,
                activated_OB_city,
                activated_1HOUR_OB_city,
                ORDER_1_28D_OB_city,
                ORDER_1_OB_city,
                ORDER_20_28D_OB_city,
                ORDER_20_OB_city,
                CREATED_IN_RIDER_ADMIN_AT
            FROM (
                SELECT
                    CASE WHEN a.COUNTRY_NAME IN ('UK', 'Ireland') THEN 'UKI' ELSE a.COUNTRY_NAME END AS COUNTRY_GROUP,
                    TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) AS approved_month,
                    IFNULL(CASE WHEN b.FIRST_WORK_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END, 0) AS activated_28D_OB_city,
                    IFNULL(CASE WHEN b.FIRST_WORK_DATE IS NOT NULL THEN 1 ELSE 0 END, 0) AS activated_OB_city,
                    IFNULL(CASE WHEN b.HOURS_WORKED_CUMULATIVE >= 1 THEN 1 ELSE 0 END, 0) AS activated_1HOUR_OB_city,
                    IFNULL(CASE WHEN b.FIRST_ORDER_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END, 0) AS ORDER_1_28D_OB_city,
                    IFNULL(CASE WHEN b.FIRST_ORDER_DATE IS NOT NULL THEN 1 ELSE 0 END, 0) AS ORDER_1_OB_city,
                    IFNULL(CASE WHEN b.FIRST_20_ORDERS_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END, 0) AS ORDER_20_28D_OB_city,
                    IFNULL(CASE WHEN b.FIRST_20_ORDERS_DATE IS NOT NULL THEN 1 ELSE 0 END, 0) AS ORDER_20_OB_city,
                    CREATED_IN_RIDER_ADMIN_AT, 
                    a.onboarding_area AS CITY,
                    c.onboarding_area, 
                    case when a.onboarding_area = c.onboarding_area THEN 1 ELSE 0 END AS matches_ob_city,
        
                
                    --coalesce(c.onboarding_area, a.onboarding_area) AS CITY,   --- updated

                    b.driver_id, a.RIDER_UUID,
                    ROW_NUMBER() OVER (PARTITION BY b.driver_id ORDER BY EVENT_UPDATED_AT ASC, a.onboarding_area) AS rn
                FROM PRODUCTION.RIDERS.RIDER_LIFECYCLE_LATEST_STATUS AS a
                LEFT JOIN production.denormalised.driver_accounting_daily AS b 
                    ON CAST(a.RIDER_UUID AS STRING) = CAST(b.DRIVER_UUID AS STRING)
                --LEFT JOIN scratch.riders.zone_drn_id_to_onboarding_area AS c ON c.city_detailed = a.onboarding_area
                LEFT JOIN New_OA_Process AS c
                    ON CAST(B.driver_id AS STRING) = CAST(c.driver_id AS STRING)


                WHERE ONBOARDING_PLATFORM = 'salesforce'
                AND LIFECYCLE_MAIN_STAGE = 'application'
                AND IS_SUBSTITUTE_ACCOUNT_ON_ADMIN = 'FALSE'
                AND a.COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
                AND IS_CREATED_ON_ADMIN = 'TRUE'
                AND TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) >= '2023-11-01'
                AND DATE = (SELECT MAX(DATE) FROM production.denormalised.driver_accounting_daily)
                --and city like 'London%' -- added to test
                
                -----
                --AND ONBOARDING_AREA NOT IN (SELECT ONBOARDING_AREA FROM scratch.riders.zone_drn_id_to_onboarding_area)
                
            ) subquery
            WHERE rn = 1 AND CITY IS NOT NULL
            AND CITY IN (SELECT ONBOARDING_AREA FROM scratch.riders.zone_drn_id_to_onboarding_area)

                
        );    
/* 
-- Onboarding Data by City & Month
SELECT COUNTRY_GROUP,
                approved_month,
                activated_28D_OB_city,
                activated_OB_city,
                activated_1HOUR_OB_city,
                ORDER_1_28D_OB_city,
                ORDER_1_OB_city,
                ORDER_20_28D_OB_city,
                ORDER_20_OB_city,
                CREATED_IN_RIDER_ADMIN_AT,
                CITY,
                B.onboarding_area,
                driver_id

            FROM SF_OB_City AS A
            LEFT JOIN scratch.riders.zone_drn_id_to_onboarding_area AS B ON B.city_name = A.CITY

            WHERE approved_month = '2024-10-01' 
                AND COUNTRY_GROUP = 'UKI' 

            GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
            ORDER BY 1 DESC, 2 DESC, CITY, driver_id 
            ;
            */

-- CREATE A SUM OF ONBOARDS FOR RIDERS.RIDER_LIFECYCLE_LATEST_STATUS WHERE IS WOKING? ETC
/*SELECT DISTINCT A.CITY, B.CITY_DETAILED 

        FROM PRODUCTION.RIDERS.RIDER_LIFECYCLE_LATEST_STATUS AS A
        LEFT JOIN production.reference.city_detailed AS b ON A.CITY = b.CITY_DETAILED

        WHERE A.COUNTRY_NAME = 'UK' 
        AND ONBOARDING_PLATFORM = 'salesforce'
        AND LIFECYCLE_MAIN_STAGE = 'application'
        AND IS_SUBSTITUTE_ACCOUNT_ON_ADMIN = 'FALSE'
        AND IS_CREATED_ON_ADMIN = 'TRUE'
        ORDER BY 1, 2
        ;
*/
  
/*  --Onboarding Data rider level
SELECT * FROM SF_OB_city  where approved_month < '2024-11-01'  ORDER BY COUNTRY_GROUP DESC, approved_month desc, CITY DESC, driver_id DESC;
 */
-- ===========================================================================================================================================================
-- 2.2 SF_count_ob_riders -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE SF_count_ob_riders AS (
            SELECT
                COUNTRY_GROUP,
                approved_month,
                COUNT(driver_id) AS ob_riders_count,
                SUM(activated_28D_OB_city) AS activated_28D_OB_city,
                SUM(activated_OB_city) AS activated_OB_city,
                SUM(activated_1HOUR_OB_city) AS activated_1HOUR_OB_city,
                SUM(ORDER_1_28D_OB_city) AS ORDER_1_28D_OB_city,
                SUM(ORDER_1_OB_city) AS ORDER_1_OB_city,
                SUM(ORDER_20_28D_OB_city) AS ORDER_20_28D_OB_city,
                SUM(ORDER_20_OB_city) AS ORDER_20_OB_city

            FROM SF_OB_City
            GROUP BY COUNTRY_GROUP, approved_month
        );
/*    --Onboarding Data by Country Group & Month
SELECT * FROM SF_count_ob_riders ORDER BY COUNTRY_GROUP DESC, approved_month DESC;
 */ 
-- ===========================================================================================================================================================
-- 2.2 SF_cities_worked_in -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE SF_cities_worked_in AS (
        WITH SF_cities_worked_in1 AS ( 
            SELECT 
                a.COUNTRY_GROUP,
                a.approved_month,
                CREATED_IN_RIDER_ADMIN_AT,
                a.driver_id,
                a.city AS ob_city,
                COALESCE(C.onboarding_area, B.CITY_NAME) AS city_worked,
                ROUND(SUM(b.hrs_worked_raw),1) AS sum_hours_worked
            FROM SF_OB_City AS a 
            LEFT JOIN production.denormalised.driver_hours_worked AS b ON a.driver_id = b.driver_id
            LEFT JOIN scratch.riders.zone_drn_id_to_onboarding_area AS c ON b.zone_code = c.zone_code
            WHERE b.country_name IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
                AND TO_DATE(DATE_TRUNC('month', b.date)) >= '2023-11-01' 
            GROUP BY 1, 2, 3, 4, 5, 6
            HAVING sum_hours_worked >= 1
            ORDER BY 1, 2, 3, 4, 5, 6
        )
        SELECT 
            a.COUNTRY_GROUP,
            a.approved_month,
            TO_DATE(a.CREATED_IN_RIDER_ADMIN_AT) AS RIDER_ADMIN_CREATED_DATE,
            a.driver_id,
            a.ob_city,
            a.city_worked,
            a.sum_hours_worked,
            c.CLUSTER_PAIR,
            CASE WHEN city_worked = ob_city THEN 1 ELSE 0 END AS matches_ob_city,
            CASE WHEN matches_ob_city = 1 OR c.CLUSTER_PAIR IS NOT NULL THEN 'Same_Cluster' ELSE 'Diff_Cluster' END AS CDCluster,
            CASE WHEN e.distance_category = 'NEAR' OR f.distance_category = 'NEAR' THEN 'Near' ELSE 'Far' END AS Distance_Less_30KM,
            CASE WHEN e.distance_category = 'NEAR' OR f.distance_category = 'NEAR' OR matches_ob_city = 1 OR c.CLUSTER_PAIR IS NOT NULL THEN 1 ELSE 0 END AS Matches_Near_or_Clustered,
            e.DISTANCE_KM AS City_Detailed_Distance, f.DISTANCE_KM AS City_Name_Distance
        FROM SF_cities_worked_in1 AS a  
        LEFT JOIN CD_PAIRS2 AS c ON a.ob_city || ' - ' || a.city_worked = c.CLUSTER_PAIR
        LEFT JOIN production.reference.city_detailed AS d ON a.city_worked = d.CITY_NAME
        LEFT JOIN CITY_DISTANCES AS e ON a.ob_city || a.city_worked = e.CITY_DETAILED_COMBO
        LEFT JOIN CITY_DISTANCES_CITY_NAME AS f ON a.ob_city || a.city_worked = f.CITY_NAME_COMBO
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
        ORDER BY 1 DESC, 2, 3, 4, 5, 6 DESC
        );  

/* 
SELECT * FROM SF_cities_worked_in where DRIVER_ID = '866925' -- = 0  ORDER BY 1 DESC, 4;
-- RSC Past Month Rider Level Leakage
*/
-- ===========================================================================================================================================================
-- 2.2b SF_cities_worked_in ----- RSC Past Month Rider Level Leakage----------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
SELECT COUNTRY_GROUP, RIDER_ADMIN_CREATED_DATE, DRIVER_ID, ob_city, city_worked, sum_hours_worked, Matches_Near_or_Clustered, City_Detailed_Distance, City_Name_Distance
FROM SF_cities_worked_in 
where APPROVED_MONTH = '2024-11-01'  -- AND COUNTRY_GROUP = 'UKI' 
ORDER BY COUNTRY_GROUP DESC, ob_city,Matches_Near_or_Clustered DESC, DRIVER_ID,City_Detailed_Distance;

-- SELECT * FROM production.denormalised.driver_hours_worked LIMIT 5

-- ===========================================================================================================================================================
-- 2.3 SF_hours_split -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE SF_hours_split AS (
            SELECT
                COUNTRY_GROUP,
                approved_month,
                driver_id,
                SUM(CASE WHEN matches_ob_city = 0 THEN sum_hours_worked ELSE 0 END) AS hours_elsewhere,
                SUM(CASE WHEN matches_ob_city = 1 THEN sum_hours_worked ELSE 0 END) AS hours_obcity,
                SUM(sum_hours_worked) AS hours_total,
                SUM(CASE WHEN matches_ob_city = 0 THEN sum_hours_worked ELSE 0 END) / SUM(DISTINCT sum_hours_worked) AS pct_hours_elsewhere,
                CASE WHEN pct_hours_elsewhere >= 0.5 THEN 1 ELSE 0 END AS mostly_worked_elsewhere,

                SUM(CASE WHEN Matches_Near_or_Clustered = 0 THEN sum_hours_worked ELSE 0 END) AS hours_far,
                SUM(CASE WHEN Matches_Near_or_Clustered = 1 THEN sum_hours_worked ELSE 0 END) AS hours_near,
                hours_far / hours_total AS pct_hours_far,
                CASE WHEN pct_hours_far >= 0.5 THEN 1 ELSE 0 END AS mostly_worked_far
            FROM SF_cities_worked_in
            GROUP BY 1, 2, 3
            ORDER BY 1 DESC, 2, 3
        );
/*
SELECT * FROM SF_hours_split ORDER BY 1 DESC, 2, 3;
*/

-- ===========================================================================================================================================================
-- 2.4 SF_FINAL_QUERY -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE SF_FINAL_QUERY AS (
        SELECT
            a.COUNTRY_GROUP AS "Country Group",
            a.approved_month AS "Approved Month",
            b.ob_riders_count AS "Riders Onboarded",
            activated_28D_OB_city AS "Activated 28 Days",
            activated_OB_city AS "Activated",
            activated_1HOUR_OB_city AS "Activated 1 Hour",
            ORDER_1_28D_OB_city AS ">=1 Order 28 Days",
            ORDER_1_OB_city AS ">=1 Order",
            ORDER_20_28D_OB_city AS ">=20 Orders 28 Days",
            ORDER_20_OB_city AS ">=20 Orders",
            COUNT(DISTINCT a.driver_id) AS "Activated 1 Hour DHW",
            ROUND(COUNT(DISTINCT a.driver_id) / NULLIF(b.ob_riders_count, 0), 3) AS "Activated 1 Hour Rate",

            ROUND(COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders Never Worked in OB City",
            COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) AS "Riders Never Worked in OB City",
            ROUND(SUM(a.mostly_worked_elsewhere) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders with >50% Hours Not in OB City",
            ROUND(SUM(a.hours_obcity) / SUM(a.hours_total), 3) AS "% Hours Worked in OB City",
            ROUND(SUM(a.hours_elsewhere) / SUM(a.hours_total), 3) AS "% Hours Worked Outside of OB City",
            ROUND(SUM(a.hours_obcity), 0) AS "Hours Worked in OB City",
            ROUND(SUM(a.hours_elsewhere), 0) AS "Hours Worked Outside of OB City",

            ROUND(COUNT(CASE WHEN a.hours_near = 0 THEN 1 END) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders Never Worked Near OB City",
            COUNT(CASE WHEN a.hours_near = 0 THEN 1 END) AS "Riders Never Worked Near OB City",
            ROUND(SUM(a.mostly_worked_far) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders with >50% Hours Not Near OB City",
            ROUND(SUM(a.hours_near) / SUM(a.hours_total), 3) AS "% Hours Worked Near OB City",
            ROUND(SUM(a.hours_far) / SUM(a.hours_total), 3) AS "% Hours Worked Far from OB City",
            ROUND(SUM(a.hours_near), 0) AS "Hours Worked Near OB City",
            ROUND(SUM(a.hours_far), 0) AS "Hours Worked Far from OB City"   
        
        FROM SF_hours_split AS a
        LEFT JOIN SF_count_ob_riders AS b ON a.approved_month = b.approved_month AND a.COUNTRY_GROUP = b.COUNTRY_GROUP
        WHERE a.approved_month >= '2023-11-01' 
        GROUP BY 1,2,3,4,5,6,7,8,9,10
        ORDER BY 1 DESC, 2 DESC
        );  


/* 
SELECT * FROM SF_FINAL_QUERY ORDER BY 1 DESC, 2 DESC;
*/




---------Fountain--------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------------------------------------
------- LEAKAGE DATA FOUNTAIN PRE SF FOR EUROPE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
-- 3.1 FT_ob_rider_cityonly -------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE FT_ob_rider_cityonly AS (
            
            SELECT
                CASE WHEN a.COUNTRY_NAME = 'UK' OR a.COUNTRY_NAME = 'Ireland' THEN 'UKI'
                    ELSE a.COUNTRY_NAME
                    END AS COUNTRY_GROUP,
                TO_DATE(DATE_TRUNC('month', approved_at)) AS approved_month,
                CITY_NAME,
                CAST(driver_id_mapping AS STRING) AS driver_id_string,
                MAX(CASE WHEN FIRST_WORK_DATE <= DATEADD('day', 28, approved_at) THEN 1 ELSE 0 END) AS activated_28D_OB_city,
                MAX(CASE WHEN FIRST_WORK_DATE IS NOT NULL THEN 1 ELSE 0 END) AS activated_OB_city,
                MAX(CASE WHEN HOURS_WORKED_CUMULATIVE >= 1 THEN 1 ELSE 0 END) AS activated_1HOUR_OB_city,
                MAX(CASE WHEN FIRST_ORDER_DATE <= DATEADD('day', 28, approved_at) THEN 1 ELSE 0 END) AS ORDER_1_28D_OB_city,
                MAX(CASE WHEN FIRST_ORDER_DATE IS NOT NULL THEN 1 ELSE 0 END) AS ORDER_1_OB_city,
                MAX(CASE WHEN FIRST_20_ORDERS_DATE <= DATEADD('day', 28, approved_at) THEN 1 ELSE 0 END) AS ORDER_20_28D_OB_city,
                MAX(CASE WHEN FIRST_20_ORDERS_DATE IS NOT NULL THEN 1 ELSE 0 END) AS ORDER_20_OB_city
            FROM production.rider_onboarding.rider_applicants_high_level AS a
            LEFT JOIN production.reference.city_detailed AS b ON a.CITY_DETAILED = b.CITY_DETAILED
            LEFT JOIN production.denormalised.driver_accounting_daily AS c ON CAST(a.driver_id_mapping AS STRING) = CAST(c.driver_id AS STRING)
            WHERE a.COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
                AND TO_DATE(DATE_TRUNC('month', approved_at)) >= '2021-01-01'
                AND driver_id_mapping IS NOT NULL
                AND applicant_current_stage IN ('Account created', 'Account Created')
                AND c.DATE = (SELECT MAX(DATE) FROM production.denormalised.driver_accounting_daily)
            GROUP BY 1, 2, 3, 4
            ORDER BY 1, 2, 3, 4
        );

-- ===========================================================================================================================================================
-- 3.2 FT_count_ob_riders -- Create temporary table for counting onboarded riders----------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE FT_count_ob_riders AS (
            SELECT
                COUNTRY_GROUP,
                approved_month,
                COUNT(DISTINCT driver_id_string) AS ob_riders_count,
                SUM(activated_28D_OB_city) activated_28D_OB_city,
                sum(activated_OB_city) AS activated_OB_city,
                SUM(activated_1HOUR_OB_city) AS activated_1HOUR_OB_city,
                SUM(ORDER_1_28D_OB_city) AS ORDER_1_28D_OB_city,
                SUM(ORDER_1_OB_city) AS ORDER_1_OB_city,
                SUM(ORDER_20_28D_OB_city) AS ORDER_20_28D_OB_city,
                SUM(ORDER_20_OB_city) AS ORDER_20_OB_city

            FROM FT_ob_rider_cityonly
            GROUP BY 1,2
            ORDER BY 1,2
        );



-- ===========================================================================================================================================================
-- 3.3 FT_cities_worked_in -- Create temporary table for cities worked in-------------------------------------------------------------------------------------------------------------------------
-- =================================================================================================================================================----------
CREATE OR REPLACE TEMPORARY TABLE FT_cities_worked_in AS (
        WITH FT_cities_worked_in1 AS ( 
            SELECT 
                a.COUNTRY_GROUP,
                a.approved_month,
                b.driver_id,
                a.city_name AS ob_city,
                c.city_name AS city_worked,
                ROUND(SUM(b.hrs_worked_raw),1) AS sum_hours_worked
            FROM FT_ob_rider_cityonly AS a 
            LEFT JOIN production.denormalised.driver_hours_worked AS b ON a.driver_id_string = b.driver_id
            LEFT JOIN production.reference.city_detailed AS c ON b.zone_code = c.zone_code
            WHERE b.country_name IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
                AND TO_DATE(DATE_TRUNC('month', b.date)) >= '2021-01-01' 
            GROUP BY 1, 2, 3, 4, 5
            HAVING sum_hours_worked >= 1
            ORDER BY 1 desc, 2, 3, 4, 5, 6
        )
        SELECT 
            a.COUNTRY_GROUP,
            a.approved_month,
            a.driver_id,
            a.ob_city,
            a.city_worked,
            a.sum_hours_worked,
            c.CLUSTER_PAIR,
            CASE WHEN city_worked = ob_city THEN 1 ELSE 0 END AS matches_ob_city,
            CASE WHEN matches_ob_city = 1 OR c.CLUSTER_PAIR IS NOT NULL THEN 'Same_Cluster' ELSE 'Diff_Cluster' END AS CDCluster,
            CASE WHEN e.distance_category = 'NEAR' OR f.distance_category = 'NEAR' THEN 'Near' ELSE 'Far' END AS Distance_Less_30KM,
            CASE WHEN e.distance_category = 'NEAR' OR f.distance_category = 'NEAR' OR matches_ob_city = 1 OR c.CLUSTER_PAIR IS NOT NULL THEN 1 ELSE 0 END AS Matches_Near_or_Clustered,
            e.DISTANCE_KM AS City_Detailed_Distance, f.DISTANCE_KM AS City_Name_Distance
        FROM FT_cities_worked_in1 AS a  
        LEFT JOIN CD_PAIRS2 AS c ON a.ob_city || ' - ' || a.city_worked = c.CLUSTER_PAIR
        LEFT JOIN production.reference.city_detailed AS d ON a.city_worked = d.CITY_NAME
        LEFT JOIN CITY_DISTANCES AS e ON a.ob_city || a.city_worked = e.CITY_DETAILED_COMBO
        LEFT JOIN CITY_DISTANCES_CITY_NAME AS f ON a.ob_city || a.city_worked = f.CITY_NAME_COMBO
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
        ORDER BY 1 DESC, 2, 3, 4, 5, 6 DESC
        );

/* 
SELECT * FROM FT_cities_worked_in2 ORDER BY 1 DESC, 2, 3, 4, 5, 6 DESC;
*/

-- ===========================================================================================================================================================
-- 3.4 FT_hours_split -- Create temporary table for splitting hours worked in-------------------------------------------------------------------------------------------------------------------------
-- =================================================================================================================================================----------
CREATE OR REPLACE TEMPORARY TABLE FT_hours_split AS (
            SELECT
                COUNTRY_GROUP,
                approved_month,
                driver_id,
                SUM(CASE WHEN matches_ob_city = 0 THEN sum_hours_worked ELSE 0 END) AS hours_elsewhere,
                SUM(CASE WHEN matches_ob_city = 1 THEN sum_hours_worked ELSE 0 END) AS hours_obcity,
                SUM(sum_hours_worked) AS hours_total,
                SUM(CASE WHEN matches_ob_city = 0 THEN sum_hours_worked ELSE 0 END) / SUM(DISTINCT sum_hours_worked) AS pct_hours_elsewhere,
                CASE WHEN pct_hours_elsewhere >= 0.5 THEN 1 ELSE 0 END AS mostly_worked_elsewhere,

                SUM(CASE WHEN Matches_Near_or_Clustered = 0 THEN sum_hours_worked ELSE 0 END) AS hours_far,
                SUM(CASE WHEN Matches_Near_or_Clustered = 1 THEN sum_hours_worked ELSE 0 END) AS hours_near,
                hours_far / hours_total AS pct_hours_far,
                CASE WHEN pct_hours_far >= 0.5 THEN 1 ELSE 0 END AS mostly_worked_far
            FROM FT_cities_worked_in
            GROUP BY 1, 2, 3
            ORDER BY 1 DESC, 2, 3
        );
/*
SELECT * FROM FT_hours_split ORDER BY 1 DESC, 2, 3;
*/

-- ===========================================================================================================================================================
-- 3.5 FT_FINAL_QUERY -- Create temporary table for final query-------------------------------------------------------------------------------------------------------------------------
-- =================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE FT_FINAL_QUERY AS (
        SELECT
            a.COUNTRY_GROUP AS "Country Group",
            a.approved_month AS "Approved Month",
            b.ob_riders_count AS "Riders Onboarded",
            activated_28D_OB_city AS "Activated 28 Days",
            activated_OB_city AS "Activated",
            activated_1HOUR_OB_city AS "Activated 1 Hour",
            ORDER_1_28D_OB_city AS ">=1 Order 28 Days",
            ORDER_1_OB_city AS ">=1 Order",
            ORDER_20_28D_OB_city AS ">=20 Orders 28 Days",
            ORDER_20_OB_city AS ">=20 Orders",
            COUNT(DISTINCT a.driver_id) AS "Activated 1 Hour DHW",
            ROUND(COUNT(DISTINCT a.driver_id) / NULLIF(b.ob_riders_count, 0), 3) AS "Activated 1 Hour Rate",

            ROUND(COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders Never Worked in OB City",
            COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) AS "Riders Never Worked in OB City",
            ROUND(SUM(a.mostly_worked_elsewhere) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders with >50% Hours Not in OB City",
            ROUND(SUM(a.hours_obcity) / SUM(a.hours_total), 3) AS "% Hours Worked in OB City",
            ROUND(SUM(a.hours_elsewhere) / SUM(a.hours_total), 3) AS "% Hours Worked Outside of OB City",
            ROUND(SUM(a.hours_obcity), 0) AS "Hours Worked in OB City",
            ROUND(SUM(a.hours_elsewhere), 0) AS "Hours Worked Outside of OB City",

            ROUND(COUNT(CASE WHEN a.hours_near = 0 THEN 1 END) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders Never Worked Near OB City",
            COUNT(CASE WHEN a.hours_near = 0 THEN 1 END) AS "Riders Never Worked Near OB City",
            ROUND(SUM(a.mostly_worked_far) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders with >50% Hours Not Near OB City",
            ROUND(SUM(a.hours_near) / SUM(a.hours_total), 3) AS "% Hours Worked Near OB City",
            ROUND(SUM(a.hours_far) / SUM(a.hours_total), 3) AS "% Hours Worked Far from OB City",
            ROUND(SUM(a.hours_near), 0) AS "Hours Worked Near OB City",
            ROUND(SUM(a.hours_far), 0) AS "Hours Worked Far from OB City"   
        
        FROM FT_hours_split AS a
        LEFT JOIN FT_count_ob_riders AS b ON a.approved_month = b.approved_month AND a.COUNTRY_GROUP = b.COUNTRY_GROUP
        GROUP BY 1,2,3,4,5,6,7,8,9,10
        ORDER BY 1 DESC, 2 DESC
        );

-- ===========================================================================================================================================================
-- 3.6 FINAL FINAL QUERY - Union of SF and Fountain-------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================================
CREATE OR REPLACE TEMPORARY TABLE FINAL_FINAL AS
        (
        SELECT *
        FROM FT_FINAL_QUERY
        UNION ALL
        SELECT *
        FROM SF_FINAL_QUERY
        )
        ;

-- ===========================================================================================================================================================
-- 3.7 FINAL Result-------------------------------------------------------------------------------------------------------------------------
-- =================================================================================================================================================

SELECT *
FROM FINAL_FINAL
WHERE "Approved Month" <> '2023-10-01' ----- excluding Oct as SF transition some data in Fountain some SF
ORDER BY 1 DESC, 2 DESC