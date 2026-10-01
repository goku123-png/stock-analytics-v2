{{ config(materialized='table', schema='marts') }}

SELECT
    c.company_key,
    d.date_key AS month_date_key,
    m.*

FROM {{ ref('int_monthly_volume_signals') }} AS m

LEFT JOIN {{ ref('dim_company') }} AS c
    ON m.ticker = c.ticker

LEFT JOIN {{ ref('dim_date') }} AS d
    ON m.month_start = d.full_date