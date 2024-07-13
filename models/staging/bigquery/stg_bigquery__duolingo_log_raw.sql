with

source as (
    select * from {{ source('bigquery', 'duolingo_log_raw') }}
),

renamed as (

    select
        -- ids
        user_id
        , lexeme_id

        -- strings
        , learning_language
        , ui_language as native_language
        , lexeme_string
        , ui_language || '-' || learning_language as language_pair_code

        -- numerics
        , p_recall as probability_recall_word

        , delta as lag_seconds_since_last_practice
        , delta / 3600 as lag_hours_since_last_practice
        , delta / 86400 as lag_days_since_last_practice
        
        , history_seen as total_times_seen_word
        , history_correct as total_times_correct_word
        , (history_correct / NULLIF(history_seen, 0)) as history_learning_rate

        , session_seen as session_times_seen_word
        , session_correct as session_times_correct_word
        , (session_correct / NULLIF(session_seen, 0)) as session_learning_rate

        --measure how familiar a user is with a lexeme
        --number of times a lexeme has been seen historically
        , LOG(1 + history_seen) as lexeme_familiarity

        --time effectiveness combined with recall rate
        , (p_recall / NULLIF(LOG(1 + delta), 0)) as time_effectiveness_since_last_practice
        
        --probability of remembering a lexeme decreases over time since last practice
        , EXP(-delta / 86400) as time_decay_factor
         
        --measure change in probability recall between current record and next one
        --adjusted by time interval since last practice
        --normalized to hours
        , (LEAD(p_recall, 1) OVER (PARTITION BY user_id, lexeme_id ORDER BY timestamp_seconds(`timestamp`)) - p_recall) 
            / GREATEST(delta / 3600, 1) as forgetting_rate
        
        -- timestamps
        , timestamp_seconds(`timestamp`) as timestamp_datetime
        , DATE(timestamp_seconds(`timestamp`)) as timestamp_date
        , TIME(timestamp_seconds(`timestamp`)) as timestamp_time

    from source
),

native_language_english as (
    select
        *
    from renamed
    where native_language = 'en'
)

select * from native_language_english