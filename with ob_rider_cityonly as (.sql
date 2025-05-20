with ob_rider_cityonly as (
select
      approved_at
    , city_detailed
    , cast(driver_id_mapping as string) as driver_id_string
from production.rider_onboarding.rider_applicants_high_level

where country_name in ('UK', 'Ireland')
  and approved_at IS NOT NULL
  and driver_id_mapping is not null
  and applicant_current_stage in ('Account created','Account Created')
group by 1,2,3
)

select
      c.approved_at
    , cast(a.driver_id as string) as driver_id_string
    , c.city_detailed as ob_city
    , b.city_detailed as city_worked
    , case when city_worked = ob_city then 1 else 0 end as matches_ob_city
    , sum(a.hrs_worked_raw) as sum_hours_worked
    , case when 1=1 THEN MAX(MATCHES_OB_CITY) OVER (PARTITION BY cast(a.driver_id as string)) END AS WORKED_OB_CITY
    
from production.denormalised.driver_hours_worked as a
    left join production.reference.city_detailed as b on a.zone_code = b.zone_code
    inner join ob_rider_cityonly as c on cast(a.driver_id as string) = c.driver_id_string
    
where a.country_name in ('UK', 'Ireland')
  and to_date(date_trunc(month, a.date)) between '2023-02-01' and '2023-02-28' 
  
group by 1,2,3,4
    having sum_hours_worked >= 1
order by 1 desc,2,3,4 DESC
