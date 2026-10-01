{{ config(materialized='table', schema='marts') }}

WITH date_bounds AS (
    SELECT
        CAST(
            DATE_TRUNC('year', MIN(trading_date))
            AS DATE
        ) AS start_date,

        CAST(
            DATE_TRUNC('year', MAX(trading_date))
            + INTERVAL '1 year'
            - INTERVAL '1 day'
            AS DATE
        ) AS end_date

    FROM {{ ref('stg_stock_prices') }}
),

calendar AS (
    SELECT CAST(d.day AS DATE) AS full_date
    FROM date_bounds AS b,
    LATERAL GENERATE_SERIES(
        b.start_date,
        b.end_date,
        INTERVAL '1 day'
    ) AS d(day)
)

SELECT
    CAST(STRFTIME(full_date, '%Y%m%d') AS INTEGER)
        AS date_key,
    full_date,

    CAST(EXTRACT(YEAR FROM full_date) AS INTEGER)
        AS year,
    CAST(EXTRACT(QUARTER FROM full_date) AS INTEGER)
        AS quarter,
    CAST(EXTRACT(MONTH FROM full_date) AS INTEGER)
        AS month_number,
    STRFTIME(full_date, '%B') AS month_name,

    CAST(DATE_TRUNC('month', full_date) AS DATE)
        AS month_start,
    STRFTIME(full_date, '%Y-%m') AS year_month,

    CAST(EXTRACT(DAY FROM full_date) AS INTEGER)
        AS day_of_month,
    CAST(EXTRACT(ISODOW FROM full_date) AS INTEGER)
        AS day_of_week,
    STRFTIME(full_date, '%A') AS day_name,

    EXTRACT(ISODOW FROM full_date) IN (6, 7)
        AS is_weekend

FROM calendar