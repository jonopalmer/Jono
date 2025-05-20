create or replace view DRIVER_ACCOUNTING_DAILY(
	DRIVER_ID,
	DRIVER_UUID,
	DATE,
	PARENT_ACCOUNT_ID,
	PARENT_ACCOUNT_DRN_ID,
	IS_SUBSTITUTE,
	DRIVER_NAME,
	DRIVER_FIRST_NAME,
	DRIVER_EMAIL,
	DRIVER_PHONE,
	DRIVER_DOB,
	DRIVER_AGE,
	OPS_CODES,
	IS_EMPLOYEE,
	CUR_DEVICE_LANGUAGE,
	LANGUAGE_SELECTED_DURING_ONBOARDING,
	GENDER_IDENTITY,
	DATE_WEEK,
	DATE_MONTH,
	DATE_QUARTER,
	APPLICATION_DATE,
	APPLICATION_APPROVED_DATE,
	FIRST_WORK_DATE,
	FIRST_ORDER_DATE,
	FIRST_20_ORDERS_DATE,
	FIRST_50_ORDERS_DATE,
	FIRST_100_ORDERS_DATE,
	FIRST_250_ORDERS_DATE,
	LAST_WORK_DATE,
	DAYS_SINCE_APPLICATION,
	DAYS_SINCE_ACQ,
	DAYS_SINCE_LAST_WORKED,
	TOTAL_DAYS_ACTIVE,
	TOTAL_WEEKS_ACTIVE,
	TOTAL_MONTHS_ACTIVE,
	ACQ_COUNTRY_ID,
	ACQ_COUNTRY,
	ACQ_BUSINESS_UNIT,
	ACQ_REGION_NAME,
	ACQ_LARGE_CITY_REGION,
	ACQ_CITY_ID,
	ACQ_CITY,
	ACQ_CITY_DETAILED,
	ACQ_ZONE_ID,
	ACQ_ZONE,
	ACQ_PREFERRED_AREA,
	ACQ_MAIN_ADMINISTRATIVE_AREA,
	ACQ_VEHICLE,
	VEHICLE_TYPE_MOTORISED,
	ACQ_CHANNEL,
	ACQ_CHANNEL_DETAILED,
	CONTRACT_TYPE,
	CHANNEL_TYPE_REFERRAL,
	AGENCY,
	REFERRAL_CODE,
	ACQ_PAY_MODEL,
	DRIVER_AGE_AT_ACQ,
	AGE_TYPE_25,
	ACQ_COHORT_WEEK,
	ACQ_COHORT_MONTH,
	ACQ_COHORT_QUARTER,
	WEEKS_SINCE_ACQ_WEEK,
	MONTHS_SINCE_ACQ_MONTH,
	QUARTERS_SINCE_ACQ_QUARTER,
	CUR_COUNTRY_ID,
	CUR_COUNTRY,
	CUR_CITY_ID,
	CUR_CITY,
	CUR_CITY_DETAILED,
	CUR_ZONE_ID,
	CUR_ZONE,
	CUR_BUSINESS_UNIT,
	CUR_REPORTING_TIER,
	CUR_COUNTRY_GROUPING,
	CUR_REGION_NAME,
	CUR_LARGE_CITY_REGION,
	CUR_MAIN_ADMINISTRATIVE_AREA,
	CUR_VEHICLE,
	CUR_PAY_MODEL,
	CUR_PAY_GROUP_NAME,
	CUR_ADMIN_STATUS,
	RIDER_ADMIN_STATUS_NOTE,
	DAILY_STATUS,
	DAILY_FLOW,
	DAILY_FLOW_DETAIL,
	WEEKLY_STATUS,
	WEEKLY_FLOW,
	WEEKLY_FLOW_DETAIL,
	MONTHLY_STATUS,
	MONTHLY_FLOW,
	MONTHLY_FLOW_DETAIL,
	GROWTH_ACCOUNTING_DAILY_STATUS,
	GROWTH_ACCOUNTING_WEEKLY_STATUS,
	GROWTH_ACCOUNTING_MONTHLY_STATUS,
	ACTIVE_7DAYS,
	ACTIVE_14DAYS,
	ACTIVE_21DAYS,
	ACTIVE_28DAYS,
	INACTIVE_28DAYS,
	HOURS_WORKED,
	HOURS_WORKED_ADJUSTED,
	HOURS_WORKED_CUMULATIVE,
	HOURS_WORKED_PEAK_LUNCH,
	HOURS_WORKED_PEAK_DINNER,
	HOURS_WORKED_SUPER_PEAK,
	HOURS_WORKED_IN_FL_ZONES,
	HOURS_ON_ORDERS,
	HOURS_ON_ORDERS_IN_FL_ZONES,
	SUPER_PEAK_HOURS_WORKED_CUMULATIVE,
	HOURS_WORKED_IN_FL_ZONES_CUMULATIVE,
	HOURS_WORKED_EXCL_GHOST_AND_OOS,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_PEAK_LUNCH,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_PEAK_DINNER,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_SUPER_PEAK,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_PEAK_LUNCH_IN_FL_ZONES,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_PEAK_DINNER_IN_FL_ZONES,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_SUPER_PEAK_IN_FL_ZONES,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_PEAK_LUNCH_IN_AM_ZONES,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_PEAK_DINNER_IN_AM_ZONES,
	HOURS_WORKED_EXCL_GHOST_AND_OOS_SUPER_PEAK_IN_AM_ZONES,
	POTENTIAL_LUNCH_PEAK_HOURS,
	POTENTIAL_PEAK_HOURS,
	POTENTIAL_SUPER_PEAK_HOURS,
	POTENTIAL_PEAK_HOURS_FL,
	POTENTIAL_SUPER_PEAK_HOURS_FL,
	POTENTIAL_PEAK_HOURS_AM,
	POTENTIAL_SUPER_PEAK_HOURS_AM,
	POTENTIAL_LUNCH_PEAK_HOURS_EXCL_GHOST_AND_OOS,
	POTENTIAL_PEAK_HOURS_EXCL_GHOST_AND_OOS,
	POTENTIAL_SUPER_PEAK_HOURS_EXCL_GHOST_AND_OOS,
	POTENTIAL_PEAK_HOURS_FL_EXCL_GHOST_AND_OOS,
	POTENTIAL_SUPER_PEAK_HOURS_FL_EXCL_GHOST_AND_OOS,
	POTENTIAL_PEAK_HOURS_AM_EXCL_GHOST_AND_OOS,
	POTENTIAL_SUPER_PEAK_HOURS_AM_EXCL_GHOST_AND_OOS,
	PCNT_HOURS_WORKED_IN_FL_ZONES_CUMULATIVE,
	WEEKLY_HOURS_WORKED,
	WEEKLY_HOURS_WORKED_IN_FL_ZONES,
	WEEKLY_HOURS_WORKED_IN_AM_ZONES,
	WEEKLY_HOURS_WORKED_EXCL_GHOST_AND_OOS,
	WEEKLY_HOURS_WORKED_EXCL_GHOST_AND_OOS_IN_FL_ZONES,
	WEEKLY_HOURS_WORKED_EXCL_GHOST_AND_OOS_IN_AM_ZONES,
	WEEKS_ACTIVE_LAST_4_WEEKS,
	LAST_4_WEEKS_TOTAL_HOURS,
	WEEKLY_AVG_HOURS_LAST_4_WEEKS,
	WEEKLY_AVG_HOURS_LIFETIME,
	WEEKLY_WEEKEND_HOURS_WORKED,
	WEEKLY_AVG_WEEKEND_HOURS_LAST_4_WEEKS,
	WEEKLY_HOURS_WORKED_SUPER_PEAK,
	WEEKLY_AVG_SUPER_PEAK_HOURS_LAST_4_WEEKS,
	WEEKLY_AVG_SUPER_PEAK_HOURS_LIFETIME,
	WEEKLY_AVG_NON_SUPER_PEAK_HOURS_LAST_4_WEEKS,
	WEEKLY_AVG_NON_SUPER_PEAK_HOURS_LIFETIME,
	MONTHLY_HOURS_WORKED,
	TOTAL_HOURS_2_MONTHS_AGO,
	MONTHLY_AVG_HOURS_LIFETIME,
	LAST_12_WEEKS_TOTAL_ORDERS,
	LAST_12_WEEKS_TOTAL_OFF_PEAK_ORDERS,
	LAST_12_WEEKS_TOTAL_PEAK_LUNCH_ORDERS,
	LAST_12_WEEKS_TOTAL_PEAK_DINNER_ORDERS,
	LAST_12_WEEKS_TOTAL_SUPER_PEAK_ORDERS,
	ORDERS_DELIVERED,
	ORDERS_DELIVERED_CUMULATIVE,
	ORDERS_DELIVERED_SUPER_PEAK_CUMULATIVE,
	ORDERS_DELIVERED_WEEKEND_CUMULATIVE,
	CNT_PEAK_LUNCH_ORDERS,
	CNT_PEAK_DINNER_ORDERS,
	CNT_SUPER_PEAK_ORDERS,
	CNT_OFF_PEAK_ORDERS,
	CNT_NON_PEAK_DINNER_ORDERS,
	CNT_WEEKEND_ORDERS,
	WEEKLY_ORDERS_DELIVERED,
	MONTHLY_ORDERS_DELIVERED,
	CNT_B10_ORDERS,
	CNT_B10_OMDNR_ORDERS,
	CNT_B10_REJECTION_ORDERS,
	CNT_B10_UNACCEPTABLE_LATE_ORDERS,
	CNT_B10_CANCELLATION_ORDERS,
	CNT_B10_MISSING_ITEM_ORDERS,
	CNT_B10_AMENDED_ORDERS,
	CNT_B10_SPOILED_FOOD_ORDERS,
	CNT_B10_RIDER_INFLUENCEABLE_ORDERS,
	CNT_UNASSIGNMENTS,
	CNT_ORDERS_REJECTED_IN_APP,
	CNT_TOTAL_ASSIGNMENTS,
	UNASSIGNMENT_RATE_LAST_4_WEEKS,
	UNASSIGNMENT_RATE_LIFETIME,
	DAILY_UNASSIGNMENT_RATE,
	WEEKLY_UNASSIGNMENT_RATE,
	CNT_CONTRACTS,
	CNT_CONTRACTS_BOOKED,
	CNT_CONTRACTS_CANCELLED,
	CNT_CONTRACTS_ATTENDED,
	SUM_CONTRACTS_DURATION_MINS,
	SUM_CONTRACTS_DURATION_BOOKED_MINS,
	SUM_CONTRACTS_DURATION_CANCELLED_MINS,
	SUM_CONTRACTS_DURATION_WORKED_MINS,
	SUPER_PEAK_ORDER_FLAG,
	DINNER_PEAK_ORDER_FLAG,
	WEEKEND_ORDER_FLAG,
	RIDER_HOURS_PAID,
	RIDER_EARNINGS_EXCL_NON_CPO_ADJUSTMENTS,
	RIDER_EARNINGS_INCL_ALL_ADJUSTMENTS,
	RIDER_EARNINGS_INCL_ALL_ADJUSTMENTS_PLUS_TIP,
	RIDER_EARNINGS_EXCL_NON_CPO_ADJUSTMENTS_GBP,
	RIDER_EARNINGS_INCL_ALL_ADJUSTMENTS_GBP,
	RIDER_EARNINGS_INCL_ALL_ADJUSTMENTS_PLUS_TIP_GBP,
	CNT_FEEDBACKS,
	CNT_BAD_BEHAVIOUR,
	CNT_NO_HELMENT_REMOVAL,
	CNT_NO_THERMAL_BAGS,
	CNT_NO_DELIVEROO_CLOTHING,
	CNT_ORDERS_WITH_NEGATIVE_FEEDBACKS,
	CNT_GOOD_JOB_FEEDBACK,
	CNT_DID_A_GREAT_JOB,
	CNT_BEHAVED_UNPROFESSIONALLY,
	CNT_HEALTH_AND_SAFETY,
	SCORE_OUT_OF_5,
	SCORE_OUT_OF_100,
	MOST_COMMON_ZONE_ID_HRS_WORKED_3WKS,
	MOST_COMMON_ZONE_CODE_HRS_WORKED_3WKS,
	MOST_COMMON_ZONE_CODE_HRS_WORKED,
	REFERRALS,
	REFERRALS_CUMULATIVE,
	REFERRED_RIDERS,
	REFERRED_RIDERS_CUMULATIVE,
	REFERRED_RIDERS_20_ORDERS,
	REFERRED_RIDERS_20_ORDERS_CUMULATIVE,
	PREDICTED_PROBABILITY_ACTIVE,
	PREDICTED_28_DAY_ACTIVE_DAYS,
	CRM_LIFE_CYCLE_STATUS,
	CRM_2WEEK_SCORE,
	CRM_2WEEK_SCORE_NAME,
	BRAZE_RANDOM_BUCKET,
	BRAZE_EMAIL_SUBSCRIBE,
	BRAZE_PUSH_SUBSCRIBE,
	EMAIL_SEND_CNT,
	EMAIL_OPEN_CNT,
	EMAIL_CLICK_CNT,
	EMAIL_SOFT_BOUNCE_CNT,
	EMAIL_BOUNCE_CNT,
	EMAIL_SPAM_CNT,
	EMAIL_UNSUBSCRIBE_CNT,
	PUSH_SEND_CNT,
	PUSH_OPEN_CNT,
	INAPP_IMPRESSION_CNT,
	INAPP_CLICK_CNT,
	WEBHOOK_SEND_CNT,
	ENTRY_CNT,
	CAMPAIGNS,
	ORDER_MILESTONE_FLAG,
	ORDER_MILESTONE_FLAG_VALUE,
	ITEM_TOTAL_COST,
	ITEM_TOTAL_COST_CUMULATIVE,
	CORE_ITEM_COST,
	CORE_ITEM_COST_CUMULATIVE,
	NON_CORE_ITEM_COST,
	NON_CORE_ITEM_COST_CUMULATIVE,
	ORDER_COUNT,
	ORDER_CUMULATIVE,
	LAST_ORDER_DATE,
	LAST_CORE_ORDER_DATE,
	LAST_V3_ORDER_DATE,
	ORDER_DELIVERED_SINCE_LAST_KIT_REPLACEMENT,
	CORE_ORDER_COUNT,
	CORE_ORDER_CUMULATIVE,
	BUNDLE_ORDER_COUNT,
	BUNDLE_ORDER_CUMULATIVE,
	V3_ORDER_COUNT,
	V3_ORDER_CUMULATIVE,
	NON_CORE_ORDER_COUNT,
	NON_CORE_ORDER_CUMULATIVE,
	PROMO_2000_ORDER_COUNT,
	PROMO_4000_ORDER_COUNT,
	PROMO_6000_ORDER_COUNT,
	PROMO_8000_ORDER_COUNT,
	PROMO_10000_ORDER_COUNT,
	PROMO_MODULO_2000_ORDER_COUNT,
	DISCOUNT_CODE_USED,
	DAYS_SINCE_APPLICATION_APPROVED_DATE,
	DAYS_SINCE_LAST_ORDER,
	DAYS_SINCE_LAST_CORE_ORDER,
	DAYS_SINCE_LAST_V3_ORDER,
	LAGGED_DAYS_SINCE_LAST_ORDER,
	LAGGED_DAYS_SINCE_LAST_CORE_ORDER,
	ORDER_CUMULATIVE_LEAD_8WEEK,
	CORE_ORDER_CUMULATIVE_LEAD_8WEEK,
	BUNDLE_ORDER_CUMULATIVE_LEAD_8WEEK,
	NON_CORE_ORDER_CUMULATIVE_LEAD_8WEEK,
	CORE_ITEM_COST_CUMULATIVE_LEAD_8WEEK,
	TOTAL_ITEM_COST_CUMULATIVE_LEAD_26WEEK,
	RECENCY_SCORE,
	FREQUENCY_SCORE,
	MONETARY_SCORE,
	PEAK_MONETARY_SCORE,
	TENURE_SCORE,
	RIDER_SEGMENTATION_NAME,
	RIDER_SEGMENTATION_NAME_HIGH_LEVEL,
	ZENDESK_TICKET_COUNT,
	ZENDESK_TICKET_COUNT_CUMULATIVE,
	PHONE_NUMBER_CHANGES,
	EMAIL_CHANGES,
	PHONE_NUMBER_CHANGES_TO_NEW_NUMBER,
	EMAIL_CHANGES_TO_NEW_EMAIL,
	RIDER_MEDALLIA_SURVEY_COUNT,
	RIDER_WEARING_ANY_DELIVEROO_KIT_CNT,
	WAS_RIDER_WEARING_DELIVEROO_JACKET_YES_CNT,
	WAS_RIDER_WEARING_DELIVEROO_JACKET_NO_CNT,
	WAS_RIDER_WEARING_DELIVEROO_JACKET_DONT_KNOW_CNT,
	WAS_RIDER_WEARING_DELIVEROO_BACKPACK_YES_CNT,
	WAS_RIDER_WEARING_DELIVEROO_BACKPACK_NO_CNT,
	WAS_RIDER_WEARING_DELIVEROO_BACKPACK_DONT_KNOW_CNT,
	WAS_RIDER_WEARING_DELIVEROO_THERMALBAG_YES_CNT,
	WAS_RIDER_WEARING_DELIVEROO_THERMALBAG_NO_CNT,
	WAS_RIDER_WEARING_DELIVEROO_THERMALBAG_DONT_KNOW_CNT,
	RRNPS_SURVEY_TYPE,
	RRNPS_SURVEY_PLATFORM,
	RRNPS_SURVEY_LANGUAGE,
	RRNPS_ALERT_TYPE,
	RRNPS_ALERT_STATUS,
	RRNPS_COMMENT_INTIAL,
	RRNPS_SCORE,
	RRNPS_SATISFACTION_OVERALL,
	RRNPS_SATISFACTION_WITH_FLEXIBILITY_SCORE,
	RRNPS_SATISFACTION_WITH_PAY,
	RRNPS_SATISFACTION_WITH_ORDERS,
	RRNPS_SATISFACTION_WITH_KIT,
	RRNPS_SATISFACTION_WITH_COMMUNICATIONS,
	RRNPS_SATISFACTION_WITH_SUPPORT,
	RRNPS_SATISFACTION_WITH_APP,
	RRNPS_SATISFACTION_WITH_SAFETY,
	RRNPS_SATISFACTION_WITH_PERKS,
	RRNPS_SATISFACTION_WITH_CUSTOMERS_EXP,
	RRNPS_SATISFACTION_WITH_RX_EXP,
	RRNPS_SATISFACTION_WITH_FLEXIBILITY,
	RRNPS_IMPORTANCE_OF_PAY,
	RRNPS_IMPORTANCE_OF_ORDERS,
	RRNPS_IMPORTANCE_OF_KIT,
	RRNPS_IMPORTANCE_OF_COMMUNICATIONS,
	RRNPS_IMPORTANCE_OF_SUPPORT,
	RRNPS_IMPORTANCE_OF_APP,
	RRNPS_IMPORTANCE_OF_SAFETY,
	RRNPS_IMPORTANCE_OF_PERKS,
	RRNPS_IMPORTANCE_OF_CUSTOMERS_EXP,
	RRNPS_IMPORTANCE_OF_RX_EXP,
	RRNPS_COMMENT_FINAL,
	RRNPS_TOPICS_SENTIMENTS_TAGGED,
	RRNPS_FEES_PER_ORDER,
	RRNPS_ACKNOWLEDGES_CONTRIBUTION,
	RRNPS_GOOD_AMOUNT_OF_ORDERS,
	RRNPS_LISTEN_FEEDBACK,
	RRNPS_MAXIMISE_EARNINGS,
	RRNPS_ROO_APP_EASY_TO_USE,
	RRNPS_RIDER_SAFETY,
	RRNPS_RECONTACT,
	SUM_WEIGHTED_SUPER_PEAK_ORDERS,
	SUM_WEIGHTED_OTHER_DINNER_PEAK_ORDERS,
	SUM_WEIGHTED_LUNCH_PEAK_ORDERS,
	SUM_WEIGHTED_OFF_PEAK_ORDERS,
	SUM_WEIGHTED_ORDERS,
	MOST_WORKED_COUNTRY_PER_WEEK,
	MOST_WORKED_CLUSTER_PER_WEEK,
	MOST_WORKED_CITY_PER_WEEK,
	WEEKLY_WEIGHTED_ORDER_RANK_PER_MOST_WORKED_COUNTRY,
	WEEKLY_WEIGHTED_ORDER_PCT_RANK_PER_MOST_WORKED_COUNTRY,
	WEEKLY_WEIGHTED_ORDER_RANK_PER_MOST_WORKED_CLUSTER,
	WEEKLY_WEIGHTED_ORDER_PCT_RANK_PER_MOST_WORKED_CLUSTER,
	WEEKLY_WEIGHTED_ORDER_RANK_PER_MOST_WORKED_CITY,
	WEEKLY_WEIGHTED_ORDER_PCT_RANK_PER_MOST_WORKED_CITY,
	MOST_WORKED_COUNTRY_PER_MONTH,
	MOST_WORKED_CLUSTER_PER_MONTH,
	MOST_WORKED_CITY_PER_MONTH,
	MONTHLY_WEIGHTED_ORDER_RANK_PER_MOST_WORKED_COUNTRY,
	MONTHLY_WEIGHTED_ORDER_PCT_RANK_PER_MOST_WORKED_COUNTRY,
	MONTHLY_WEIGHTED_ORDER_RANK_PER_MOST_WORKED_CLUSTER,
	MONTHLY_WEIGHTED_ORDER_PCT_RANK_PER_MOST_WORKED_CLUSTER,
	MONTHLY_WEIGHTED_ORDER_RANK_PER_MOST_WORKED_CITY,
	MONTHLY_WEIGHTED_ORDER_PCT_RANK_PER_MOST_WORKED_CITY,
	PREVIOUS_MOST_WORKED_CITY_PER_WEEK,
	PREVIOUS_MOST_WORKED_CITY_PER_MONTH,
	PREVIOUS_WEEKLY_WEIGHTED_ORDER_PCT_RANK_PER_MOST_WORKED_CITY,
	PREVIOUS_MONTHLY_WEIGHTED_ORDER_PCT_RANK_PER_MOST_WORKED_CITY,
	POISSON_RIDER_ISSUE_PROB_56,
	PLATFORM,
	APP_VERSION,
	PLATFORM_APP_VERSION,
	APP_BUILD,
	DEVICE_MODEL,
	OS_VERSION
) WITH TAG (PRODUCTION.ADMIN.CRITICALITY='3-Medium', PRODUCTION.ADMIN.INCREMENTAL='False', PRODUCTION.ADMIN.OWNER='Rider', PRODUCTION.ADMIN.PIPELINE='bi-pipeline', PRODUCTION.ADMIN.PRIMARY_KEY='date, driver_id')
 COMMENT='Rider details per day since the day they were onboarded (ie. Rider-Date granularity). It provides hours worked, orders delivered, earnings, CRM status, segments that the rider fell into for each day. This table is good to see a snapshot of a rider profile at a given period of time.'
 as
SELECT
  tbl.driver_id
  , tbl.driver_uuid
  , tbl.date
  , tbl.parent_account_id
  , tbl.parent_account_drn_id
  , tbl.is_substitute
  , tbl.driver_name
  , tbl.driver_first_name
  , tbl.driver_email
  , tbl.driver_phone
  , tbl.driver_dob
  , tbl.driver_age
  , tbl.ops_codes
  , tbl.is_employee
  , tbl.cur_device_language
  , tbl.language_selected_during_onboarding
  , tbl.gender_identity
  , tbl.date_week
  , tbl.date_month
  , tbl.date_quarter
  , tbl.application_date
  , tbl.application_approved_date
  , tbl.first_work_date
  , tbl.first_order_date
  , tbl.first_20_orders_date
  , tbl.first_50_orders_date
  , tbl.first_100_orders_date
  , tbl.first_250_orders_date
  , tbl.last_work_date
  , tbl.days_since_application
  , tbl.days_since_acq
  , tbl.days_since_last_worked
  , tbl.total_days_active
  , tbl.total_weeks_active
  , tbl.total_months_active
  , tbl.acq_country_id
  , tbl.acq_country
  , tbl.acq_business_unit
  , tbl.acq_region_name
  , tbl.acq_large_city_region
  , tbl.acq_city_id
  , tbl.acq_city
  , tbl.acq_city_detailed
  , tbl.acq_zone_id
  , tbl.acq_zone
  , tbl.acq_preferred_area
  , tbl.acq_main_administrative_area
  , tbl.acq_vehicle
  , tbl.vehicle_type_motorised
  , tbl.acq_channel
  , tbl.acq_channel_detailed
  , tbl.contract_type
  , tbl.channel_type_referral
  , tbl.agency
  , tbl.referral_code
  , tbl.acq_pay_model
  , tbl.driver_age_at_acq
  , tbl.age_type_25
  , tbl.acq_cohort_week
  , tbl.acq_cohort_month
  , tbl.acq_cohort_quarter
  , tbl.weeks_since_acq_week
  , tbl.months_since_acq_month
  , tbl.quarters_since_acq_quarter
  , tbl.cur_country_id
  , tbl.cur_country
  , tbl.cur_city_id
  , tbl.cur_city
  , tbl.cur_city_detailed
  , tbl.cur_zone_id
  , tbl.cur_zone
  , tbl.cur_business_unit
  , tbl.cur_reporting_tier
  , tbl.cur_country_grouping
  , tbl.cur_region_name
  , tbl.cur_large_city_region
  , tbl.cur_main_administrative_area
  , tbl.cur_vehicle
  , tbl.cur_pay_model
  , tbl.cur_pay_group_name
  , tbl.cur_admin_status
  , tbl.rider_admin_status_note
  , tbl.daily_status
  , tbl.daily_flow
  , tbl.daily_flow_detail
  , tbl.weekly_status
  , tbl.weekly_flow
  , tbl.weekly_flow_detail
  , tbl.monthly_status
  , tbl.monthly_flow
  , tbl.monthly_flow_detail
  , tbl.growth_accounting_daily_status
  , tbl.growth_accounting_weekly_status
  , tbl.growth_accounting_monthly_status
  , tbl.active_7days
  , tbl.active_14days
  , tbl.active_21days
  , tbl.active_28days
  , tbl.inactive_28days
  , tbl.hours_worked
  , tbl.hours_worked_adjusted
  , tbl.hours_worked_cumulative
  , tbl.hours_worked_peak_lunch
  , tbl.hours_worked_peak_dinner
  , tbl.hours_worked_super_peak
  , tbl.hours_worked_in_fl_zones
  , tbl.hours_on_orders
  , tbl.hours_on_orders_in_fl_zones
  , tbl.super_peak_hours_worked_cumulative
  , tbl.hours_worked_in_fl_zones_cumulative
  , tbl.hours_worked_excl_ghost_and_oos
  , tbl.hours_worked_excl_ghost_and_oos_peak_lunch
  , tbl.hours_worked_excl_ghost_and_oos_peak_dinner
  , tbl.hours_worked_excl_ghost_and_oos_super_peak
  , tbl.hours_worked_excl_ghost_and_oos_peak_lunch_in_fl_zones
  , tbl.hours_worked_excl_ghost_and_oos_peak_dinner_in_fl_zones
  , tbl.hours_worked_excl_ghost_and_oos_super_peak_in_fl_zones
  , tbl.hours_worked_excl_ghost_and_oos_peak_lunch_in_am_zones
  , tbl.hours_worked_excl_ghost_and_oos_peak_dinner_in_am_zones
  , tbl.hours_worked_excl_ghost_and_oos_super_peak_in_am_zones
  , tbl.potential_lunch_peak_hours
  , tbl.potential_peak_hours
  , tbl.potential_super_peak_hours
  , tbl.potential_peak_hours_fl
  , tbl.potential_super_peak_hours_fl
  , tbl.potential_peak_hours_am
  , tbl.potential_super_peak_hours_am
  , tbl.potential_lunch_peak_hours_excl_ghost_and_oos
  , tbl.potential_peak_hours_excl_ghost_and_oos
  , tbl.potential_super_peak_hours_excl_ghost_and_oos
  , tbl.potential_peak_hours_fl_excl_ghost_and_oos
  , tbl.potential_super_peak_hours_fl_excl_ghost_and_oos
  , tbl.potential_peak_hours_am_excl_ghost_and_oos
  , tbl.potential_super_peak_hours_am_excl_ghost_and_oos
  , tbl.pcnt_hours_worked_in_fl_zones_cumulative
  , tbl.weekly_hours_worked
  , tbl.weekly_hours_worked_in_fl_zones
  , tbl.weekly_hours_worked_in_am_zones
  , tbl.weekly_hours_worked_excl_ghost_and_oos
  , tbl.weekly_hours_worked_excl_ghost_and_oos_in_fl_zones
  , tbl.weekly_hours_worked_excl_ghost_and_oos_in_am_zones
  , tbl.weeks_active_last_4_weeks
  , tbl.last_4_weeks_total_hours
  , tbl.weekly_avg_hours_last_4_weeks
  , tbl.weekly_avg_hours_lifetime
  , tbl.weekly_weekend_hours_worked
  , tbl.weekly_avg_weekend_hours_last_4_weeks
  , tbl.weekly_hours_worked_super_peak
  , tbl.weekly_avg_super_peak_hours_last_4_weeks
  , tbl.weekly_avg_super_peak_hours_lifetime
  , tbl.weekly_avg_non_super_peak_hours_last_4_weeks
  , tbl.weekly_avg_non_super_peak_hours_lifetime
  , tbl.monthly_hours_worked
  , tbl.total_hours_2_months_ago
  , tbl.monthly_avg_hours_lifetime
  , tbl.last_12_weeks_total_orders
  , tbl.last_12_weeks_total_off_peak_orders
  , tbl.last_12_weeks_total_peak_lunch_orders
  , tbl.last_12_weeks_total_peak_dinner_orders
  , tbl.last_12_weeks_total_super_peak_orders
  , tbl.orders_delivered
  , tbl.orders_delivered_cumulative
  , tbl.orders_delivered_super_peak_cumulative
  , tbl.orders_delivered_weekend_cumulative
  , tbl.cnt_peak_lunch_orders
  , tbl.cnt_peak_dinner_orders
  , tbl.cnt_super_peak_orders
  , tbl.cnt_off_peak_orders
  , tbl.cnt_non_peak_dinner_orders
  , tbl.cnt_weekend_orders
  , tbl.weekly_orders_delivered
  , tbl.monthly_orders_delivered
  , tbl.cnt_b10_orders
  , tbl.cnt_b10_omdnr_orders
  , tbl.cnt_b10_rejection_orders
  , tbl.cnt_b10_unacceptable_late_orders
  , tbl.cnt_b10_cancellation_orders
  , tbl.cnt_b10_missing_item_orders
  , tbl.cnt_b10_amended_orders
  , tbl.cnt_b10_spoiled_food_orders
  , tbl.cnt_b10_rider_influenceable_orders
  , tbl.cnt_unassignments
  , tbl.cnt_orders_rejected_in_app
  , tbl.cnt_total_assignments
  , tbl.unassignment_rate_last_4_weeks
  , tbl.unassignment_rate_lifetime
  , tbl.daily_unassignment_rate
  , tbl.weekly_unassignment_rate
  , tbl.cnt_contracts
  , tbl.cnt_contracts_booked
  , tbl.cnt_contracts_cancelled
  , tbl.cnt_contracts_attended
  , tbl.sum_contracts_duration_mins
  , tbl.sum_contracts_duration_booked_mins
  , tbl.sum_contracts_duration_cancelled_mins
  , tbl.sum_contracts_duration_worked_mins
  , tbl.super_peak_order_flag
  , tbl.dinner_peak_order_flag
  , tbl.weekend_order_flag
  , tbl.rider_hours_paid
  , tbl.rider_earnings_excl_non_cpo_adjustments
  , tbl.rider_earnings_incl_all_adjustments
  , tbl.rider_earnings_incl_all_adjustments_plus_tip
  , tbl.rider_earnings_excl_non_cpo_adjustments_gbp
  , tbl.rider_earnings_incl_all_adjustments_gbp
  , tbl.rider_earnings_incl_all_adjustments_plus_tip_gbp
  , tbl.cnt_feedbacks
  , tbl.cnt_bad_behaviour
  , tbl.cnt_no_helment_removal
  , tbl.cnt_no_thermal_bags
  , tbl.cnt_no_deliveroo_clothing
  , tbl.cnt_orders_with_negative_feedbacks
  , tbl.cnt_good_job_feedback
  , tbl.cnt_did_a_great_job
  , tbl.cnt_behaved_unprofessionally
  , tbl.cnt_health_and_safety
  , tbl.score_out_of_5
  , tbl.score_out_of_100
  , tbl.most_common_zone_id_hrs_worked_3wks
  , tbl.most_common_zone_code_hrs_worked_3wks
  , tbl.most_common_zone_code_hrs_worked
  , tbl.referrals
  , tbl.referrals_cumulative
  , tbl.referred_riders
  , tbl.referred_riders_cumulative
  , tbl.referred_riders_20_orders
  , tbl.referred_riders_20_orders_cumulative
  , tbl.predicted_probability_active
  , tbl.predicted_28_day_active_days
  , tbl.crm_life_cycle_status
  , tbl.crm_2week_score
  , tbl.crm_2week_score_name
  , tbl.braze_random_bucket
  , tbl.braze_email_subscribe
  , tbl.braze_push_subscribe
  , tbl.email_send_cnt
  , tbl.email_open_cnt
  , tbl.email_click_cnt
  , tbl.email_soft_bounce_cnt
  , tbl.email_bounce_cnt
  , tbl.email_spam_cnt
  , tbl.email_unsubscribe_cnt
  , tbl.push_send_cnt
  , tbl.push_open_cnt
  , tbl.inapp_impression_cnt
  , tbl.inapp_click_cnt
  , tbl.webhook_send_cnt
  , tbl.entry_cnt
  , tbl.campaigns
  , tbl.order_milestone_flag
  , tbl.order_milestone_flag_value
  , tbl.item_total_cost
  , tbl.item_total_cost_cumulative
  , tbl.core_item_cost
  , tbl.core_item_cost_cumulative
  , tbl.non_core_item_cost
  , tbl.non_core_item_cost_cumulative
  , tbl.order_count
  , tbl.order_cumulative
  , tbl.last_order_date
  , tbl.last_core_order_date
  , tbl.last_v3_order_date
  , tbl.order_delivered_since_last_kit_replacement
  , tbl.core_order_count
  , tbl.core_order_cumulative
  , tbl.bundle_order_count
  , tbl.bundle_order_cumulative
  , tbl.v3_order_count
  , tbl.v3_order_cumulative
  , tbl.non_core_order_count
  , tbl.non_core_order_cumulative
  , tbl.promo_2000_order_count
  , tbl.promo_4000_order_count
  , tbl.promo_6000_order_count
  , tbl.promo_8000_order_count
  , tbl.promo_10000_order_count
  , tbl.promo_modulo_2000_order_count
  , tbl.discount_code_used
  , tbl.days_since_application_approved_date
  , tbl.days_since_last_order
  , tbl.days_since_last_core_order
  , tbl.days_since_last_v3_order
  , tbl.lagged_days_since_last_order
  , tbl.lagged_days_since_last_core_order
  , tbl.order_cumulative_lead_8week
  , tbl.core_order_cumulative_lead_8week
  , tbl.bundle_order_cumulative_lead_8week
  , tbl.non_core_order_cumulative_lead_8week
  , tbl.core_item_cost_cumulative_lead_8week
  , tbl.total_item_cost_cumulative_lead_26week
  , tbl.recency_score
  , tbl.frequency_score
  , tbl.monetary_score
  , tbl.peak_monetary_score
  , tbl.tenure_score
  , tbl.rider_segmentation_name
  , tbl.rider_segmentation_name_high_level
  , tbl.zendesk_ticket_count
  , tbl.zendesk_ticket_count_cumulative
  , tbl.phone_number_changes
  , tbl.email_changes
  , tbl.phone_number_changes_to_new_number
  , tbl.email_changes_to_new_email
  , tbl.rider_medallia_survey_count
  , tbl.rider_wearing_any_deliveroo_kit_cnt
  , tbl.was_rider_wearing_deliveroo_jacket_yes_cnt
  , tbl.was_rider_wearing_deliveroo_jacket_no_cnt
  , tbl.was_rider_wearing_deliveroo_jacket_dont_know_cnt
  , tbl.was_rider_wearing_deliveroo_backpack_yes_cnt
  , tbl.was_rider_wearing_deliveroo_backpack_no_cnt
  , tbl.was_rider_wearing_deliveroo_backpack_dont_know_cnt
  , tbl.was_rider_wearing_deliveroo_thermalbag_yes_cnt
  , tbl.was_rider_wearing_deliveroo_thermalbag_no_cnt
  , tbl.was_rider_wearing_deliveroo_thermalbag_dont_know_cnt
  , tbl.rrnps_survey_type
  , tbl.rrnps_survey_platform
  , tbl.rrnps_survey_language
  , tbl.rrnps_alert_type
  , tbl.rrnps_alert_status
  , tbl.rrnps_comment_intial
  , tbl.rrnps_score
  , tbl.rrnps_satisfaction_overall
  , tbl.rrnps_satisfaction_with_flexibility_score
  , tbl.rrnps_satisfaction_with_pay
  , tbl.rrnps_satisfaction_with_orders
  , tbl.rrnps_satisfaction_with_kit
  , tbl.rrnps_satisfaction_with_communications
  , tbl.rrnps_satisfaction_with_support
  , tbl.rrnps_satisfaction_with_app
  , tbl.rrnps_satisfaction_with_safety
  , tbl.rrnps_satisfaction_with_perks
  , tbl.rrnps_satisfaction_with_customers_exp
  , tbl.rrnps_satisfaction_with_rx_exp
  , tbl.rrnps_satisfaction_with_flexibility
  , tbl.rrnps_importance_of_pay
  , tbl.rrnps_importance_of_orders
  , tbl.rrnps_importance_of_kit
  , tbl.rrnps_importance_of_communications
  , tbl.rrnps_importance_of_support
  , tbl.rrnps_importance_of_app
  , tbl.rrnps_importance_of_safety
  , tbl.rrnps_importance_of_perks
  , tbl.rrnps_importance_of_customers_exp
  , tbl.rrnps_importance_of_rx_exp
  , tbl.rrnps_comment_final
  , tbl.rrnps_topics_sentiments_tagged
  , tbl.rrnps_fees_per_order
  , tbl.rrnps_acknowledges_contribution
  , tbl.rrnps_good_amount_of_orders
  , tbl.rrnps_listen_feedback
  , tbl.rrnps_maximise_earnings
  , tbl.rrnps_roo_app_easy_to_use
  , tbl.rrnps_rider_safety
  , tbl.rrnps_recontact
  , tbl.sum_weighted_super_peak_orders
  , tbl.sum_weighted_other_dinner_peak_orders
  , tbl.sum_weighted_lunch_peak_orders
  , tbl.sum_weighted_off_peak_orders
  , tbl.sum_weighted_orders
  , tbl.most_worked_country_per_week
  , tbl.most_worked_cluster_per_week
  , tbl.most_worked_city_per_week
  , tbl.weekly_weighted_order_rank_per_most_worked_country
  , tbl.weekly_weighted_order_pct_rank_per_most_worked_country
  , tbl.weekly_weighted_order_rank_per_most_worked_cluster
  , tbl.weekly_weighted_order_pct_rank_per_most_worked_cluster
  , tbl.weekly_weighted_order_rank_per_most_worked_city
  , tbl.weekly_weighted_order_pct_rank_per_most_worked_city
  , tbl.most_worked_country_per_month
  , tbl.most_worked_cluster_per_month
  , tbl.most_worked_city_per_month
  , tbl.monthly_weighted_order_rank_per_most_worked_country
  , tbl.monthly_weighted_order_pct_rank_per_most_worked_country
  , tbl.monthly_weighted_order_rank_per_most_worked_cluster
  , tbl.monthly_weighted_order_pct_rank_per_most_worked_cluster
  , tbl.monthly_weighted_order_rank_per_most_worked_city
  , tbl.monthly_weighted_order_pct_rank_per_most_worked_city
  , tbl.previous_most_worked_city_per_week
  , tbl.previous_most_worked_city_per_month
  , tbl.previous_weekly_weighted_order_pct_rank_per_most_worked_city
  , tbl.previous_monthly_weighted_order_pct_rank_per_most_worked_city
  , tbl.poisson_rider_issue_prob_56
  , tbl.platform
  , tbl.app_version
  , tbl.platform_app_version
  , tbl.app_build
  , tbl.device_model
  , tbl.os_version
FROM denormalised.driver_accounting_daily_tbl tbl
CROSS JOIN snowflake_admin.security.history_row_level_access hist 
 
WHERE (
  hist.history_access_type = 'ALL'
  OR COALESCE(tbl.date, CURRENT_DATE()) BETWEEN hist.min_date AND hist.max_date
)
AND (
  EXISTS (SELECT 1 AS col FROM snowflake_admin.security.region_row_level_access WHERE country_name = 'ALL')
  OR tbl.cur_country IN (SELECT country_name FROM snowflake_admin.security.region_row_level_access)
)
;