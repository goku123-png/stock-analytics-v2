WITH standardized AS (
    SELECT
        UPPER(TRIM(ticker)) AS ticker,
        CAST("Date" AS DATE) AS trading_date,
        CAST("Open" AS DOUBLE) AS open_price,
        CAST("High" AS DOUBLE) AS high_price,
        CAST("Low" AS DOUBLE) AS low_price,
        CAST("Close" AS DOUBLE) AS close_price,
        CAST("Adj Close" AS DOUBLE) AS adjusted_close_price,
        CAST("Volume" AS BIGINT) AS volume,
        source_run_id
    FROM {{ source('stock_raw', 'stock_prices') }}
)

SELECT
    ticker || '_' || CAST(trading_date AS VARCHAR) AS stock_date_key,
    *
FROM standardized