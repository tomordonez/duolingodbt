with

traces as (
    select
        learning_language_name
        , day_of_week_name
        , created_at
        , session_learning_rate as raw_session_learning_rate
        , forgetting_rate as raw_forgetting_rate

    from {{ ref('int_analytics_learning_traces') }}
),

create_rounded_hour as (
    select
        learning_language_name
        , day_of_week_name
        , timestamp_trunc(created_at, hour) as rounded_hour
        , raw_session_learning_rate
        , raw_forgetting_rate
    from traces
),

remove_outliers as (
    select
        learning_language_name
        , day_of_week_name
        , rounded_hour
        , (raw_session_learning_rate - AVG(raw_session_learning_rate) OVER()) / STDDEV(raw_session_learning_rate) OVER() AS standardized_session_learning_rate
        , (raw_forgetting_rate - AVG(raw_forgetting_rate) OVER()) / STDDEV(raw_forgetting_rate) OVER() AS standardized_forgetting_rate
    from create_rounded_hour
),

normalize_zero_to_one as (
    select
        learning_language_name
        , day_of_week_name
        , rounded_hour
        , (standardized_session_learning_rate - MIN(standardized_session_learning_rate) OVER()) / (MAX(standardized_session_learning_rate) OVER() - MIN(standardized_session_learning_rate) OVER()) AS session_learning_rate
        , (standardized_forgetting_rate - MIN(standardized_forgetting_rate) OVER()) / (MAX(standardized_forgetting_rate) OVER() - MIN(standardized_forgetting_rate) OVER()) AS forgetting_rate
    from remove_outliers
),

hourly_analysis_learning as (
    select
        learning_language_name
        , day_of_week_name
        , extract(hour from rounded_hour) as hour_of_day
        , avg(session_learning_rate) as avg_hourly_learning_rate
        , avg(forgetting_rate) as avg_hourly_forgetting_rate
    from normalize_zero_to_one
    group by learning_language_name, day_of_week_name, hour_of_day
)

select * from hourly_analysis_learning