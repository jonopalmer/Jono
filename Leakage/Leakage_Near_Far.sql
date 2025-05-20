SELECT
    A.ZONE_CODE,
    B.city_detailed,
    A.city_name,
    CENTROID_GEO_LAT,
    CENTROID_GEO_LONG
FROM PRODUCTION.REFERENCE.ZONE_CITY_COUNTRY A 
LEFT JOIN reference.city_detailed B ON A.zone_code = B.ZONE_CODE
WHERE A.COUNTRY_NAME IN ('France', 'UK')
    AND B.CITY_DETAILED IS NOT NULL
ORDER BY 3,2,1
;
--- TABLE WITH ONBOARDING AREA INSTEAD OF CD?
WITH city_list AS
(SELECT
    B.city_detailed AS CITY,
    AVG(CENTROID_GEO_LAT) AS GEO_LAT, 
    AVG(CENTROID_GEO_LONG) AS GEO_LONG
FROM PRODUCTION.REFERENCE.ZONE_CITY_COUNTRY A 
LEFT JOIN reference.city_detailed B ON A.zone_code = B.ZONE_CODE
WHERE A.COUNTRY_NAME IN ('Ireland', 'UK')
    AND B.CITY_DETAILED IS NOT NULL
GROUP BY B.city_detailed
)

SELECT A.CITY || B.CITY AS CITY_COMBO,
    A.CITY AS CITY_1, 
    B.CITY AS CITY_2, 
    A.GEO_LAT AS CITY_1_LAT,
    A.GEO_LONG AS CITY_1_LONG,
    B.GEO_LAT AS CITY_2_LAT,
    B.GEO_LONG AS CITY_2_LONG,
    ROUND(haversine(A.GEO_LAT, A.GEO_LONG, B.GEO_LAT, B.GEO_LONG),0) AS DISTANCE_KM,
    ROUND((DISTANCE_KM * 0.621371),0) AS DISTANCE_MILES,
    CASE WHEN DISTANCE_KM < 15 THEN 'NEAR'
         WHEN DISTANCE_KM < 30 THEN 'NOT_FAR'
        ELSE 'FAR'
    END AS DISTANCE_CATEGORY 
FROM city_list A
CROSS JOIN city_list B
ORDER BY 1,2
;

--TEMP 
with ob_rider_cityonly as (
select
  to_date(date_trunc(month, approved_at)) as approved_month
, city_detailed
, cast(driver_id_mapping as string) as driver_id_string
from production.rider_onboarding.rider_applicants_high_level
where country_name in ('UK')
  and to_date(date_trunc(month, approved_at)) between '2021-01-01' and '2022-07-01'
  and driver_id_mapping is not null
  and applicant_current_stage in ('Account created','Account Created')
group by 1,2,3
),

count_ob_riders as (
select
  to_date(date_trunc(month, approved_at)) as approved_month
, count(distinct cast(driver_id_mapping as string)) as ob_riders_count
from production.rider_onboarding.rider_applicants_high_level
where country_name in ('UK')
  and to_date(date_trunc(month, approved_at)) between '2021-01-01' and '2022-07-01'
  and driver_id_mapping is not null
  and applicant_current_stage in ('Account created','Account Created')
group by 1
),

cities_worked_in as (
select
  c.approved_month
, cast(a.driver_id as string) as driver_id_string
, c.city_detailed as ob_city
, b.city_detailed as city_worked
, case when city_worked = ob_city then 1 else 0 end as matches_ob_city
, sum(a.hrs_worked_raw) as sum_hours_worked
from production.denormalised.driver_hours_worked as a
    left join production.reference.city_detailed as b on a.zone_code = b.zone_code
    inner join ob_rider_cityonly as c on cast(a.driver_id as string) = c.driver_id_string
where a.country_name in ('UK')
  and to_date(date_trunc(month, a.date)) between '2021-01-01' and '2022-07-01'
group by 1,2,3,4,5
    having sum_hours_worked >= 1
order by 1,2,3,4,5 DESC
),

hours_split as (
select
  approved_month
, driver_id_string
, sum(case when matches_ob_city = 0 then sum_hours_worked else 0 end) as hours_elsewhere
, sum(case when matches_ob_city = 1 then sum_hours_worked else 0 end) as hours_obcity
, sum(sum_hours_worked) as hours_total
, hours_elsewhere / hours_total as pct_hours_elsewhere
, case when pct_hours_elsewhere >= 0.5 then 1 else 0 end as mostly_worked_elsewhere
from cities_worked_in
group by 1,2
order by 1,2
)

select
  a.approved_month
, b.ob_riders_count as riders_onboarded
, count(distinct a.driver_id_string) as riders_activated
, riders_activated / riders_onboarded as activation_rate
, count(case when a.hours_obcity = 0 then 1 end) / count(distinct a.driver_id_string) as "% riders never worked in OB city"
, count(case when a.hours_obcity = 0 then 1 end) as "riders never worked in OB city"
, sum(a.mostly_worked_elsewhere) / count(distinct a.driver_id_string) as "% riders >50% hours not in OB city"
, sum(a.hours_obcity) / sum(a.hours_total) as "% Hours worked in OB city"
, sum(a.hours_elsewhere) / sum(a.hours_total) as "% Hours worked outside of OB city"
, sum(a.hours_obcity) as "Hours worked in OB city"
, sum(a.hours_elsewhere) as "Hours worked outside of OB city"
from hours_split as a
    left join count_ob_riders as b on a.approved_month = b.approved_month
group by 1,2
order by 1

;



select
cast(a.driver_id as string) as driver_id_string
, city_name
, sum(a.hrs_worked_raw) as sum_hours_worked

from production.denormalised.driver_hours_worked as a

where a.driver_id = '871320'
group by 1,2
order by 1,2,3
;

--------THE SF SIDE---------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY TABLE SF_OB_city1 AS (
    SELECT
        CASE WHEN a.COUNTRY_NAME = 'UK' OR a.COUNTRY_NAME = 'Ireland' THEN 'UKI'
            ELSE a.COUNTRY_NAME
            END AS COUNTRY_GROUP,
        TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) AS approved_month,
        CASE WHEN b.FIRST_WORK_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS activated_28D_OB_city,
        CASE WHEN b.FIRST_WORK_DATE IS NOT NULL THEN 1 ELSE 0 END AS activated_OB_city,
        CASE WHEN b.HOURS_WORKED_CUMULATIVE >= 1 THEN 1 ELSE 0 END AS activated_1HOUR_OB_city,
        CASE WHEN b.FIRST_ORDER_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS ORDER_1_28D_OB_city,
        CASE WHEN b.FIRST_ORDER_DATE IS NOT NULL THEN 1 ELSE 0 END AS ORDER_1_OB_city,
        CASE WHEN b.FIRST_20_ORDERS_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS ORDER_20_28D_OB_city,
        CASE WHEN b.FIRST_20_ORDERS_DATE IS NOT NULL THEN 1 ELSE 0 END AS ORDER_20_OB_city,
        CREATED_IN_RIDER_ADMIN_AT,
        a.CITY,  --- SHOULD BE CITY DETAIL
        b.driver_id,
        ROW_NUMBER() OVER (PARTITION BY a.RIDER_UUID ORDER BY CREATED_IN_RIDER_ADMIN_AT ASC, a.CITY) AS rn
    FROM PRODUCTION.RIDERS.RIDER_LIFECYCLE_LATEST_STATUS AS a
    
    INNER JOIN production.denormalised.denormalised_driver dd
        ON a.RIDER_UUID = dd.UUID
        AND dd.IS_SUBSTITUTE = FALSE

    LEFT JOIN production.denormalised.driver_accounting_daily AS b ON CAST(a.RIDER_UUID AS STRING) = CAST(b.DRIVER_UUID AS STRING)
    WHERE ONBOARDING_PLATFORM = 'salesforce'
      AND LIFECYCLE_MAIN_STAGE = 'application'
      AND a.COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
      AND IS_CREATED_ON_ADMIN = 'TRUE'
      AND TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) >= '2023-11-01'
      AND DATE = (SELECT MAX(DATE) FROM production.denormalised.driver_accounting_daily)
     
);

SELECT DISTINCT CITY, COUNTRY_NAME FROM PRODUCTION.RIDERS.RIDER_LIFECYCLE_LATEST_STATUS WHERE COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland') ORDER BY 2,1;

CREATE OR REPLACE TEMPORARY TABLE SF_ob_rider_cityonly AS (
    SELECT
        COUNTRY_GROUP,
        approved_month,
        city,
        activated_28D_OB_city,
        activated_OB_city,
        activated_1HOUR_OB_city,
        ORDER_1_28D_OB_city,
        ORDER_1_OB_city,
        ORDER_20_28D_OB_city,
        ORDER_20_OB_city,
        CREATED_IN_RIDER_ADMIN_AT,
        driver_id
    FROM SF_OB_city1
    WHERE rn = 1
);

CREATE OR REPLACE TEMPORARY TABLE SF_count_ob_riders AS (
    SELECT
        COUNTRY_GROUP,
        approved_month,
        COUNT(driver_id) AS ob_riders_count,
        SUM(activated_28D_OB_city) activated_28D_OB_city,
        sum(activated_OB_city) AS activated_OB_city,
        SUM(activated_1HOUR_OB_city) AS activated_1HOUR_OB_city,
        SUM(ORDER_1_28D_OB_city) AS ORDER_1_28D_OB_city,
        SUM(ORDER_1_OB_city) AS ORDER_1_OB_city,
        SUM(ORDER_20_28D_OB_city) AS ORDER_20_28D_OB_city,
        SUM(ORDER_20_OB_city) AS ORDER_20_OB_city

    FROM SF_ob_rider_cityonly
    GROUP BY COUNTRY_GROUP, approved_month
);

CREATE OR REPLACE TEMPORARY TABLE SF_cities_worked_in AS (
    SELECT 
        a.COUNTRY_GROUP,
        a.approved_month,
        CREATED_IN_RIDER_ADMIN_AT,
        a.driver_id,
        a.city AS ob_city,
        d.city_detailed AS city_worked,
        b.city_name AS city_worked_city_name,
        CASE 
            WHEN city_worked = ob_city OR city_worked_city_name = ob_city THEN 1 
            ELSE 0 
        END AS matches_ob_city,
        CASE WHEN matches_ob_city = 1 OR c.DISTANCE_CATEGORY = 'NEAR' OR e.distance_category = 'NEAR' THEN 'NEAR'
            ELSE 'FAR'
        END AS DISTANCE,

        SUM(b.hrs_worked_raw) AS sum_hours_worked
    FROM SF_ob_rider_cityonly AS a 
    LEFT JOIN production.denormalised.driver_hours_worked AS b ON a.driver_id = b.driver_id
    LEFT JOIN CITY_DISTANCES AS c ON a.city || b.city_name = c.CITY_COMBO
    LEFT JOIN production.reference.city_detailed as D on B.zone_code = D.zone_code
    LEFT JOIN CITY_DISTANCES_CITY_NAME AS e ON a.city || b.city_name  = e.CITY_COMBO
    WHERE b.country_name IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
        AND TO_DATE(DATE_TRUNC('month', b.date)) >= '2023-11-01' 
    GROUP BY 1, 2, 3, 4, 5, 6, 7,8,9
    HAVING sum_hours_worked >= 1
    ORDER BY 1, 2, 3, 4, 5, 6 DESC
);

SELECT *
FROM SF_cities_worked_in
ORDER BY 1 DESC, 2, 3, 4, 5, 6 DESC
;

CREATE OR REPLACE TEMPORARY TABLE SF_hours_split AS (
    SELECT
        COUNTRY_GROUP,
        approved_month,
        driver_id,
        distance,
        SUM(CASE WHEN matches_ob_city = 0 THEN sum_hours_worked ELSE 0 END) AS hours_elsewhere,
        SUM(CASE WHEN matches_ob_city = 1 THEN sum_hours_worked ELSE 0 END) AS hours_obcity,
        SUM(sum_hours_worked) AS hours_total,
        hours_elsewhere / hours_total AS pct_hours_elsewhere,
        CASE 
            WHEN pct_hours_elsewhere >= 0.5 THEN 1 
            ELSE 0 
        END AS mostly_worked_elsewhere,
        SUM(CASE WHEN DISTANCE = 'NEAR' THEN sum_hours_worked ELSE 0 END) AS hours_NEAR,
        SUM(CASE WHEN DISTANCE <> 'NEAR' THEN sum_hours_worked ELSE 0 END) AS hours_FAR,
        hours_FAR / hours_total AS pct_hours_FAR,
        CASE 
            WHEN pct_hours_FAR >= 0.5 THEN 1 
            ELSE 0 
        END AS mostly_worked_FAR
    FROM SF_cities_worked_in
    GROUP BY 1, 2, 3, 4
    ORDER BY 1, 2
);
SELECT * FROM SF_hours_split ORDER BY 1, 2, 3;

CREATE OR REPLACE TEMPORARY TABLE SF_FINAL_QUERY AS
(SELECT
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

    ROUND(COUNT(CASE WHEN DISTANCE = 'NEAR' THEN 1 END) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders Never Worked NEAR OB City",
    COUNT(CASE WHEN DISTANCE = 'NEAR' THEN 1 END) AS "Riders Never Worked NEAR OB City",
    ROUND(SUM(a.mostly_worked_FAR) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders with >50% Hours Not NEAR OB City",
    ROUND(SUM(a.hours_NEAR) / SUM(a.hours_total), 3) AS "% Hours Worked NEAR OB City",
    ROUND(SUM(a.hours_FAR) / SUM(a.hours_total), 3) AS "% Hours Worked FAR from OB City",
    ROUND(SUM(a.hours_NEAR), 0) AS "Hours Worked NEAR OB City",
    ROUND(SUM(a.hours_FAR), 0) AS "Hours Worked FAR from OB City"    


FROM SF_hours_split AS a
LEFT JOIN SF_count_ob_riders AS b ON a.approved_month = b.approved_month AND a.COUNTRY_GROUP = b.COUNTRY_GROUP
WHERE a.approved_month >= '2023-11-01' 
GROUP BY 1,2,3,4,5,6,7,8,9,10
ORDER BY 1,2
);


CREATE OR REPLACE TEMPORARY TABLE FINAL_FINAL AS
(
SELECT *
FROM FT_FINAL_QUERY

UNION ALL

SELECT *
FROM SF_FINAL_QUERY
)
;

SELECT *
FROM FINAL_FINAL
WHERE "Approved Month" <> '2023-10-01' ----- excluding Oct as SF transition some data in Fountain some SF
ORDER BY 1 DESC, 2 DESC

