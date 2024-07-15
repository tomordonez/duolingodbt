with

traces as (
    select
        learning_language_is_germanic
        , learning_language_is_romance
        , history_learning_rate as raw_history_learning_rate

    from {{ ref('int_analytics_learning_traces') }}
),

remove_outliers as (
    select
        learning_language_is_germanic
        , learning_language_is_romance
        , (raw_history_learning_rate - AVG(raw_history_learning_rate) OVER()) / STDDEV(raw_history_learning_rate) OVER() AS standardized_history_learning_rate
    from traces
),

normalize_zero_to_one as (
    select
        learning_language_is_germanic
        , learning_language_is_romance
        , (standardized_history_learning_rate - MIN(standardized_history_learning_rate) OVER()) / (MAX(standardized_history_learning_rate) OVER() - MIN(standardized_history_learning_rate) OVER()) AS history_learning_rate
    from remove_outliers
),

historical_learning as (
    select
        learning_language_is_germanic
        , learning_language_is_romance
        , avg(history_learning_rate) as avg_history_learning_rate
    from normalize_zero_to_one
    group by learning_language_is_germanic, learning_language_is_romance
)

select * from historical_learning