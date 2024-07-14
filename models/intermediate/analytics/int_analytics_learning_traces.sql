with

dim_date as (
    select * from {{ ref('dim_date') }}
),

lexeme_reference_modifier as (
    select * from {{ ref('stg_bigquery__lexeme_reference_modifier') }}
),

lexeme_reference_part_of_speech as (
    select * from {{ ref('stg_bigquery__lexeme_reference_pos') }}
),

languages as (
    select * from {{ ref('languages') }}
),

language_distances as (
    select * from {{ ref('language_distances') }}
),

duolingo_log_raw_traces as (
    select * from {{ ref('stg_bigquery__duolingo_log_raw') }}
),

raw_traces_native_language as (
    select
        traces.*
        , lang.language_name as native_language_name
        , lang.is_germanic as native_language_is_germanic
        , lang.is_romance as native_language_is_romance
    from duolingo_log_raw_traces traces
    inner join languages lang
        on traces.native_language = lang.language_code

),

raw_traces_native_language_learning_language as (
    select
        traces.*
        , lang.language_name as learning_language_name
        , lang.is_germanic as learning_language_is_germanic
        , lang.is_romance as learning_language_is_romance
    from raw_traces_native_language traces
    inner join languages lang
        on traces.learning_language = lang.language_code
),

language_traces as (
    select
        traces.*
        , dates.day_of_week
        , dates.day_of_week_name
        , dates.day_of_week_name_short
        , dates.day_of_month
        , dates.day_of_year
        , dates.week_of_year
        , dates.month_of_year
        , dates.month_name
        , dates.month_name_short
        , dates.month_start_date
        , dates.month_end_date
        , dates.year_number
    from raw_traces_native_language_learning_language traces
    inner join dim_date dates
        on traces.created_date = dates.date_day
)

select * from language_traces