with

traces as (
    select * from {{ ref('int_analytics_learning_traces') }}
),

daily_analysis_learning as (
    select
        day_of_week_name
        , learning_language_name
        , avg(session_learning_rate) as avg_daily_learning_rate
    from traces
    group by day_of_week_name, learning_language_name
)

select * from daily_analysis_learning