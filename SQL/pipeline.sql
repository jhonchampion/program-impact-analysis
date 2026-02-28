-------------------------------------------
---- Data Cleaning & Standardisation -----
--------------------------------------------

select 
  Hub_Name_, 
  State_of_Operation,
  `Survey_Round` as survey_round,

  -- Renaming verbose survey columns;
  `Our_hub_has_a_clearly_defined_and_structured_incubation_acceleration_model_` as cap_incubation_model,
  `Our_hub_has_a_documented_and_consistently_applied_startup_selection_process__` as cap_startup_selection,
  `Our_hub_systematically_tracks_startup_progress_using_defined_milestones_or_KPIs_` as cap_progress_tracking,
  `Our_hub_has_a_functional_data_collection_and_reporting_system` as cap_data_reporting,
  `Our_hub_has_a_structured_investment_readiness_support_framework_for_startups_` as cap_invest_framework,
  `Our_hub_has_an_active_and_managed_mentor_engagement_system_` as cap_mentor_active,
  `_Our_hub_has_a_defined_partnership_development_strategy` as cap_partnership,
  `Our_hub_has_a_clear_revenue_sustainability_strategy_` as cap_revenue_strategy,
  `How_many_startups_are_currently_active_in_your_hub_` as active_startups,
  `What_percentage_of_your_active_startups_are_female_led_` as pct_female_led,
  `What_percentage_of_your_active_startups_are_youth_led__founder_under_35__` as pct_youth_led,
  `How_many_jobs_were_created_by_startups_supported_by_your_hub_in_the_last_12_months_` as startup_jobs_created,
  `How_many_supported_startups_generated_revenue_in_the_last_12_months_` as no_of_startup_gen_revenue,
  `What_is_the_total_revenue_generated__NGN__by_supported_startups_in_the_last_12_months_` as startup_total_revenue,
  `How_many_supported_startups_raised_funding_in_the_last_12_months_` as no_of_startup_funds_raised,
  `What_is_the_total_funding_raised__NGN__by_supported_startups_in_the_last_12_months_` as startup_total_funds,
  `What_is_your_hub___s_annual_operating_budget__NGN__` as hub_annaual_op_budget,
  `What_percentage_of_your_operating_budget_comes_from_earned_income_` as pct_op_budget_income,
  `How_many_full_time_staff_does_your_hub_currently_employ__` as no_of_hub_full_staff,
  `How_many_active_strategic_partnerships_does_your_hub_currently_maintain_` as no_of_hub_partnership
from `gov_Survey.hub_survey_raw`

-----------------------------------------------
  ------ Capacity Index Calculation -------
-----------------------------------------------
  
SELECT *,
-- Capacity grouping
  CASE
    WHEN cap_index < 2 THEN 'Emerging'
    WHEN cap_index < 3.5 THEN 'Developing'
    WHEN cap_index < 4.5 THEN 'Established'
    ELSE 'High Performing'
  END AS capacity_band,

  -- Survey Round Order
  CASE survey_round
    WHEN 'baseline' THEN 1
    WHEN 'midline' THEN 2
    WHEN 'endline' THEN 3
  END AS survey_round_order
FROM (
  SELECT
  m.hub_id,
  m.hub_name,
  m.cohort,
  m.program_year,
  s.*,
  -- capacity index
  round((s.cap_data_reporting +
        s.cap_incubation_model +
        s.cap_invest_framework +
        s.cap_mentor_active +
        s.cap_partnership +
        s.cap_progress_tracking +
        s.cap_revenue_strategy +
        s.cap_startup_selection) / 8, 1) as cap_index 
FROM gov_Survey.hub_survey_clean s
LEFT JOIN gov_Survey.ihatch_master m -- Join the master tables with the survey tables to match with their hub id's
ON LOWER(TRIM(s.Hub_Name_)) = LOWER(TRIM(m.hub_name))
      );

---------------------------------------------
----- Longitudinal Growth Tracking -----
---------------------------------------------
SELECT
  hub_id,

  -- Capacity Index

  MAX(CASE WHEN survey_round = 'baseline' THEN cap_index END) 
      AS baseline_capacity,

  MAX(CASE WHEN survey_round = 'midline' THEN cap_index END) 
      AS midline_capacity,

  ROUND(MAX(CASE WHEN survey_round = 'midline' THEN cap_index END)
  -
  MAX(CASE WHEN survey_round = 'baseline' THEN cap_index END), 2)
      AS capacity_growth_abs,

  ROUND(SAFE_MULTIPLY(
    SAFE_DIVIDE(
      MAX(CASE WHEN survey_round = 'midline' THEN cap_index END)
      -
      MAX(CASE WHEN survey_round = 'baseline' THEN cap_index END),
      MAX(CASE WHEN survey_round = 'baseline' THEN cap_index END)
    ),
    100
  ), 2) AS capacity_growth_pct,

  -- Active Startups

  MAX(CASE WHEN survey_round = 'baseline' THEN active_startups END)
      AS baseline_active_startups,

  MAX(CASE WHEN survey_round = 'midline' THEN active_startups END)
      AS midline_active_startups,

  ROUND(MAX(CASE WHEN survey_round = 'midline' THEN active_startups END)
  -
  MAX(CASE WHEN survey_round = 'baseline' THEN active_startups END), 2)
      AS active_startups_growth_abs,

  ROUND(SAFE_MULTIPLY(
    SAFE_DIVIDE(
      MAX(CASE WHEN survey_round = 'midline' THEN active_startups END)
      -
      MAX(CASE WHEN survey_round = 'baseline' THEN active_startups END),
      MAX(CASE WHEN survey_round = 'baseline' THEN active_startups END)
    ),
    100
  ), 2) AS active_startups_growth_pct,

  -- Jobs Created

  MAX(CASE WHEN survey_round = 'baseline' THEN startup_jobs_created END)
      AS baseline_jobs,

  MAX(CASE WHEN survey_round = 'midline' THEN startup_jobs_created END)
      AS midline_jobs,

  ROUND(MAX(CASE WHEN survey_round = 'midline' THEN startup_jobs_created END)
  -
  MAX(CASE WHEN survey_round = 'baseline' THEN startup_jobs_created END), 2)
      AS jobs_growth_abs,

  ROUND(SAFE_MULTIPLY(
    SAFE_DIVIDE(
      MAX(CASE WHEN survey_round = 'midline' THEN startup_jobs_created END)
      -
      MAX(CASE WHEN survey_round = 'baseline' THEN startup_jobs_created END),
      MAX(CASE WHEN survey_round = 'baseline' THEN startup_jobs_created END)
    ),
    100
  ), 2) AS jobs_growth_pct

FROM gov_Survey.final_hub_survey
GROUP BY hub_id;


