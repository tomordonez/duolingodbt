with

source as (

    select * from {{ source('bigquery', 'lexeme_reference_pos') }}
),

renamed as (
    select
        pos_code as part_of_speech_code
        , pos_category as part_of_speech_category
        , pos_detail as part_of_speech_description
    from source
)

select * from renamed