{{ config(materialized='table', schema='marts') }}

SELECT
    s.stock_date_key,
    c.company_key,
    d.date_key,

    s.ticker,
    s.trading_date,

    s.open_price,
    s.high_price,
    s.low_price,
    s.close_price,
    s.adjusted_close_price,
    s.volume,

    s.previous_trading_date,
    s.previous_adjusted_close_price,
    s.daily_return,
    s.daily_return_pct,

    s.source_run_id

FROM {{ ref('int_daily_stock_returns') }} AS s

LEFT JOIN {{ ref('dim_company') }} AS c
    ON s.ticker = c.ticker

LEFT JOIN {{ ref('dim_date') }} AS d
    ON s.trading_date = d.full_date