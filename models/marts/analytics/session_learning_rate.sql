with

traces as (
    select
        learning_language_name
        , session_learning_rate as raw_session_learning_rate

    from {{ ref('int_analytics_learning_traces') }}
),

remove_outliers as (
    select
        learning_language_name
        , (raw_session_learning_rate - AVG(raw_session_learning_rate) OVER()) / STDDEV(raw_session_learning_rate) OVER() AS standardized_session_learning_rate
    from traces
),

normalize_zero_to_one as (
    select
        learning_language_name
        , (standardized_session_learning_rate - MIN(standardized_session_learning_rate) OVER()) / (MAX(standardized_session_learning_rate) OVER() - MIN(standardized_session_learning_rate) OVER()) AS session_learning_rate
    from remove_outliers
),

session_learning as (
    select
        learning_language_name
        , avg(session_learning_rate) as avg_session_learning_rate
    from normalize_zero_to_one
    group by learning_language_name
)

select * from session_learning