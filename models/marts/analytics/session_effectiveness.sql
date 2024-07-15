with

traces as (
    select
        learning_language_name
        , time_effectiveness_since_last_practice as raw_time_effectiveness_since_last_practice

    from {{ ref('int_analytics_learning_traces') }}
),

remove_outliers as (
    select
        learning_language_name
        , (raw_time_effectiveness_since_last_practice - AVG(raw_time_effectiveness_since_last_practice) OVER()) / STDDEV(raw_time_effectiveness_since_last_practice) OVER() AS standardized_time_effectiveness_since_last_practice
    from traces
),

normalize_zero_to_one as (
    select
        learning_language_name
        , (standardized_time_effectiveness_since_last_practice - MIN(standardized_time_effectiveness_since_last_practice) OVER()) / (MAX(standardized_time_effectiveness_since_last_practice) OVER() - MIN(standardized_time_effectiveness_since_last_practice) OVER()) AS time_effectiveness_since_last_practice
    from remove_outliers
),

session_effectiveness as (
    select
        learning_language_name
        , avg(time_effectiveness_since_last_practice) as avg_effectiveness
    from normalize_zero_to_one
    group by learning_language_name
)

select * from session_effectiveness