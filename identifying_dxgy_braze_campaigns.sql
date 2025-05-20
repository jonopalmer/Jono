
select *

FROM PRODUCTION.BRAZE.RIDER_ENGAGEMENT

where CAMPAIGN_CANVAS_NAME = 'rid-multi-ops-rec-gen-global-all-all-week9-20240226-retentionautomation' 
and canvas_step_name = 'Email_1D_Awareness'
and to_date(sent_at) = '2025-02-26'

order by driver_id, sent_at desc

--- actually sent to 87483 638606 827629

;

select r.rider_uuid as "external_id",
       s.braze_email_subscribe as "email_subscribed"
from production.braze.rider_stats_daily_log as r
         left join production.braze.braze_riders as s on r.rider_uuid = s.user_id
         where braze_email_subscribe = 'subscribed' 
         and braze_email_subscribe is not null
         and r.last_run_at::DATE  = current_date
and r.last_work_date > dateadd(week, -3, current_date)
Limit 10
;

select *
from production.braze.rider_stats_daily_log
limit 10;

