{{ config(materialized='table', schema='marts') }}

WITH yearly AS (
    SELECT
        company_key,
        ticker,
        year,

        COUNT(*) AS month_count,
        COUNT(monthly_return_pct) AS valid_month_count,

        MAX(
            CASE WHEN month_number = 1
                THEN monthly_return_pct
            END
        ) AS january_return_pct,

        AVG(
            CASE WHEN month_number BETWEEN 2 AND 12
                THEN monthly_return_pct
            END
        ) AS other_months_avg_return_pct

    FROM {{ ref('fct_monthly_stock') }}
    WHERE year BETWEEN 2016 AND 2025
    GROUP BY company_key, ticker, year
)

SELECT
    ticker || '_' || CAST(year AS VARCHAR)
        AS stock_year_key,
    company_key,
    ticker,
    year,

    CAST(
        CAST(year AS VARCHAR) || '-01-01'
        AS DATE
    ) AS year_start,

    CAST(year * 10000 + 101 AS INTEGER)
        AS year_date_key,

    month_count,
    valid_month_count,
    january_return_pct,
    other_months_avg_return_pct,

    january_return_pct - other_months_avg_return_pct
        AS january_difference_pp

FROM yearly