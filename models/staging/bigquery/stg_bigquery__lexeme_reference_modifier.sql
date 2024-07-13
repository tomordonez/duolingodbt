with

source as (

    select * from {{ source('bigquery', 'lexeme_reference_modifier') }}
),

renamed as (

    select
        modifier_code
        , modifier_category
        , modifier_detail as modifier_description
    from source
)

select * from renamed