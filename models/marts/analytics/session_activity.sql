with

traces as (
    select * from {{ ref('int_analytics_learning_traces') }}
),

session_analysis as (
    select
        learning_language_name
        , sum(session_times_seen_word) as total_sessions
        , sum(session_times_correct_word) as total_correct
        , sum(session_times_correct_word) / nullif(sum(session_times_seen_word), 0) as accuracy_rate
    from traces
    group by learning_language_name
)

select * from session_analysis