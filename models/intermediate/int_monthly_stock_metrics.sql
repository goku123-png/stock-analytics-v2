{{ config(materialized='view', schema='intermediate') }}

WITH monthly AS (
    SELECT
        ticker,
        CAST(DATE_TRUNC('month', trading_date) AS DATE)
            AS month_start,

        COUNT(*) AS trading_days,
        COUNT(daily_return) AS valid_return_days,

        SUM(volume) AS total_volume,
        AVG(volume) AS avg_daily_volume,

        AVG(daily_return) AS avg_daily_return,
        STDDEV_SAMP(daily_return) AS daily_volatility,

        FIRST(
            previous_adjusted_close_price
            ORDER BY trading_date
        ) AS previous_month_close,

        LAST(
            adjusted_close_price
            ORDER BY trading_date
        ) AS month_end_close

    FROM {{ ref('int_daily_stock_returns') }}
    GROUP BY ticker, DATE_TRUNC('month', trading_date)
)

SELECT
    ticker || '_' || CAST(month_start AS VARCHAR)
        AS stock_month_key,
    ticker,
    month_start,
    CAST(EXTRACT(YEAR FROM month_start) AS INTEGER)
        AS year,
    CAST(EXTRACT(MONTH FROM month_start) AS INTEGER)
        AS month_number,

    trading_days,
    valid_return_days,
    total_volume,
    avg_daily_volume,

    previous_month_close,
    month_end_close,

    (
        month_end_close
        / NULLIF(previous_month_close, 0) - 1
    ) * 100 AS monthly_return_pct,

    avg_daily_return * 100 AS avg_daily_return_pct,
    daily_volatility * 100 AS daily_volatility_pct

FROM monthly