{{ config(materialized='view', schema='intermediate') }}

WITH previous_prices AS (
    SELECT
        *,
        LAG(trading_date) OVER (
            PARTITION BY ticker ORDER BY trading_date
        ) AS previous_trading_date,
        LAG(adjusted_close_price) OVER (
            PARTITION BY ticker ORDER BY trading_date
        ) AS previous_adjusted_close_price
    FROM {{ ref('stg_stock_prices') }}
),

returns AS (
    SELECT
        *,
        adjusted_close_price
            / NULLIF(previous_adjusted_close_price, 0) - 1
            AS daily_return
    FROM previous_prices
)

SELECT
    *,
    daily_return * 100 AS daily_return_pct
FROM returns