with

traces as (
    select
        lexeme_id
        , learning_language_name
        , lexeme_familiarity as raw_lexeme_familiarity

    from {{ ref('int_analytics_learning_traces') }}
),

remove_outliers as (
    select
        lexeme_id
        , learning_language_name
        , (raw_lexeme_familiarity - AVG(raw_lexeme_familiarity) OVER()) / STDDEV(raw_lexeme_familiarity) OVER() AS standardized_lexeme_familiarity
    from traces
),

normalize_zero_to_one as (
    select
        lexeme_id
        , learning_language_name
        , (standardized_lexeme_familiarity - MIN(standardized_lexeme_familiarity) OVER()) / (MAX(standardized_lexeme_familiarity) OVER() - MIN(standardized_lexeme_familiarity) OVER()) AS lexeme_familiarity
    from remove_outliers
),

lexeme_learning as (
    select
        learning_language_name
        , avg(lexeme_familiarity) as avg_lexeme_familiarity
        , count(distinct lexeme_id) as num_lexemes
    from normalize_zero_to_one
    group by learning_language_name
)

select * from lexeme_learning