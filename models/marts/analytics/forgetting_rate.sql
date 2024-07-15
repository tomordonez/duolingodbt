with

traces as (
    select
        learning_language_name
        , forgetting_rate as raw_forgetting_rate

    from {{ ref('int_analytics_learning_traces') }}
),

remove_outliers as (
    select
        learning_language_name
        , (raw_forgetting_rate - AVG(raw_forgetting_rate) OVER()) / STDDEV(raw_forgetting_rate) OVER() AS standardized_forgetting_rate
    from traces
),

normalize_zero_to_one as (
    select
        learning_language_name
        , (standardized_forgetting_rate - MIN(standardized_forgetting_rate) OVER()) / (MAX(standardized_forgetting_rate) OVER() - MIN(standardized_forgetting_rate) OVER()) AS forgetting_rate
    from remove_outliers
),

forgetting_rate_analysis as (
    select
        learning_language_name
        , avg(forgetting_rate) as avg_forgetting_rate
    from normalize_zero_to_one
    group by learning_language_name
)

select * from forgetting_rate_analysis