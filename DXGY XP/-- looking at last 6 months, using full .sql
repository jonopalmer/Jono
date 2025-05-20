-- looking at last 6 months, using full weeks of data
SET end_date = DATE_TRUNC(WEEK, CURRENT_DATE) - 1;
SET start_date = DATE_TRUNC(WEEK, DATEADD(MONTH, -6, CURRENT_DATE));

-- spine for every date for every rider since they started facial rec checks
CREATE OR REPLACE TEMP TABLE scratch.riders.rider_id_date_spine AS
WITH ids AS (
  SELECT
    fae.rider_drn_id
    , fae.rider_id
    , dd.last_work_date
    , MIN(fae.created_at)::DATE AS first_check
    , MAX(IFF(fae.result = 'PASS' AND fae.created_at::DATE < $start_date, fae.created_at::DATE, NULL)) AS most_recent_pass_before_start -- to fill in last pass value for riders eligible for > 6 months
  FROM riders.rider_facial_authentication_events fae
  INNER JOIN denormalised.denormalised_driver dd
    ON fae.rider_id = dd.id
  WHERE fae.country_name IN ('UK', 'Ireland')
    AND dd.has_active_status
    AND dd.last_work_date >= $start_date -- has been active in the last 6 months
  GROUP BY 1, 2, 3
)

SELECT
  ids.rider_drn_id
  , ids.rider_id
  , ids.first_check
  , d.""date""
  , ids.most_recent_pass_before_start
FROM reference.dates d
INNER JOIN ids
  ON d.""date"" >= ids.first_check
WHERE d.""date"" BETWEEN $start_date AND $end_date
;

-- reference table of all pass dates for riders
CREATE OR REPLACE TEMP TABLE scratch.riders.rider_pass_date AS
SELECT
  fae.rider_id
  , fae.rider_drn_id
  , fae.created_at::DATE AS pass_date
  , fae.authentication_type_grouped
FROM riders.rider_facial_authentication_events fae
WHERE fae.result = 'PASS'
  AND fae.created_at::DATE >= $start_date
  AND fae.country_name IN ('UK', 'Ireland')
QUALIFY ROW_NUMBER() OVER (PARTITION BY fae.rider_id, pass_date ORDER BY fae.created_at) = 1
;

CREATE OR REPLACE TEMP TABLE scratch.riders.pass_date_with_next_check_event AS
SELECT DISTINCT
  pd.rider_id
  , pd.pass_date
  , pd.authentication_type_grouped
  , nce.next_check_date
  , COALESCE(nce.next_check_date, DATEADD(DAYS, 14, pd.pass_date)) AS next_check_due
FROM scratch.riders.rider_pass_date pd
LEFT JOIN flattened.rider_next_check_event nce
  ON pd.rider_drn_id = nce.rider_drn_id
    AND pd.pass_date = nce.created_at::DATE
QUALIFY ROW_NUMBER() OVER (PARTITION BY pd.rider_id, pd.pass_date ORDER BY nce.created_at DESC) = 1 -- where multiple check events have been created, take the latest.
;
-- E.g. RIDER_DRN_ID = '20e338de-77ad-47a0-a29d-bee8ffee3434' for pass on 2024-08-14


-- reference table of all attempt dates for riders
CREATE OR REPLACE TEMP TABLE scratch.riders.rider_attempts AS
SELECT
  rider_id
  , created_at::DATE AS attempt_date
FROM riders.rider_facial_authentication_events
WHERE attempt_date >= $start_date
  AND authentication_type_grouped != 'GRACE_PERIOD'
GROUP BY 1, 2
;

-- reference table of all dates riders opened the app
-- using any event as a proxy for app use
CREATE OR REPLACE TEMP TABLE scratch.riders.rider_app_opens AS
SELECT
  rider_id
  , received_at_date AS open_date
FROM denormalised.rider_app_events
WHERE received_at_date BETWEEN $start_date AND $end_date
  AND country_name IN ('UK', 'Ireland')
GROUP BY 1, 2
;

-- reference table of days with an event relating to identity checks
CREATE OR REPLACE TEMP TABLE scratch.riders.rider_verify_identity_shown AS
SELECT
  spine.rider_id
  , spine.""date"" AS verify_shown_date
FROM scratch.riders.rider_id_date_spine spine
INNER JOIN denormalised.rider_app_events rap
  ON spine.rider_id = rap.rider_id
    AND spine.""date"" = rap.received_at_date
    AND rap.event_name IN ('VERIFY_IDENTITY_HOME_FEED_SHOWN', 'Shown VERIFY_IDENTITY Action', 'identity_check_pageview', 'identity_check_initiated')
GROUP BY 1, 2
;

-- daily view of if the rider has passed, or had a check due or needed
CREATE OR REPLACE TEMP TABLE scratch.riders.daily_check_pass AS
SELECT
  spine.rider_id
  , spine.""date""
  , pd.pass_date
  , ncd.next_check_due IS NOT NULL AS check_due_today
  , pd.pass_date IS NOT NULL AS passed_today
  , ra.attempt_date IS NOT NULL AS attempted_today
  , ao.open_date IS NOT NULL AS opened_today
  , vis.verify_shown_date IS NOT NULL AS verify_shown_today
  , LAG(ncd.next_check_due) IGNORE NULLS OVER (PARTITION BY spine.rider_id ORDER BY spine.""date"")::DATE AS last_check_due
  , COALESCE(LAG(pd.pass_date) IGNORE NULLS OVER (PARTITION BY spine.rider_id ORDER BY spine.""date""), spine.most_recent_pass_before_start) AS last_pass
  , NOT passed_today AND last_pass < last_check_due AS check_overdue
  , COALESCE(check_due_today OR check_overdue, FALSE) AS check_needed
FROM scratch.riders.rider_id_date_spine spine
LEFT JOIN scratch.riders.pass_date_with_next_check_event pd
  ON spine.rider_id = pd.rider_id
    AND spine.""date"" = pd.pass_date
LEFT JOIN scratch.riders.pass_date_with_next_check_event ncd
  ON spine.rider_id = ncd.rider_id
    AND spine.""date"" = ncd.next_check_due
LEFT JOIN scratch.riders.rider_attempts ra
  ON spine.rider_id = ra.rider_id
    AND spine.""date"" = ra.attempt_date
LEFT JOIN scratch.riders.rider_app_opens ao
  ON spine.rider_id = ao.rider_id
    AND spine.""date"" = ao.open_date
LEFT JOIN scratch.riders.rider_verify_identity_shown vis
  ON spine.rider_id = vis.rider_id
    AND spine.""date"" = vis.verify_shown_date
;

-- weekly aggregate, was a check due or needed that week, did the rider pass that week. (may not be super accurate over checked due on sundays)
CREATE OR REPLACE TEMP TABLE scratch.riders.weekly_check_pass AS
SELECT
  DATE_TRUNC(WEEK, ""date"") AS week_start
  , rider_id
  , MAX(opened_today) AS opened_in_week
  , MAX(attempted_today) AS attempted_in_week
  , MAX(check_due_today) AS check_due_in_week
  , MAX(check_needed) AS check_needed_week
  , MAX(passed_today) AS passed_in_week
  , MAX(verify_shown_today) AS verify_shown_in_week
FROM scratch.riders.daily_check_pass
GROUP BY 1, 2
;

-- Overall, what pct of riders pass in a week where a check was needed at any point?
SELECT
  week_start
  , COUNT_IF(passed_in_week) AS count_riders_passed
  , COUNT_IF(attempted_in_week) AS count_riders_attempted_in_week
  , COUNT_IF(opened_in_week) AS count_riders_opened_app_in_week
  , COUNT_IF(verify_shown_in_week) AS count_riders_verify_shown_in_week
  , COUNT(rider_id) AS count_all_riders_due
  , count_riders_passed / NULLIFZERO(count_all_riders_due) AS pct_all_riders_passed
  , count_riders_passed / NULLIFZERO(count_riders_attempted_in_week) AS pct_attempted_riders_passed
  , count_riders_passed / NULLIFZERO(count_riders_opened_app_in_week) AS pct_opened_app_riders_passed
  , count_riders_passed / NULLIFZERO(count_riders_verify_shown_in_week) AS pct_verify_shown_riders_passed
  , count_riders_attempted_in_week / NULLIFZERO(count_all_riders_due) AS pct_attempted
FROM scratch.riders.weekly_check_pass
WHERE check_needed_week
GROUP BY 1
ORDER BY 1
;
