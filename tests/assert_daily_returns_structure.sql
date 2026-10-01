WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ticker ORDER BY trading_date
        ) AS row_num
    FROM {{ ref('int_daily_stock_returns') }}
)

SELECT stock_date_key AS issue
FROM ranked
WHERE
    (row_num = 1 AND daily_return IS NOT NULL)
    OR (row_num > 1 AND daily_return IS NULL)

UNION ALL

SELECT 'Row count differs from staging' AS issue
WHERE
    (SELECT COUNT(*) FROM {{ ref('int_daily_stock_returns') }})
    <>
    (SELECT COUNT(*) FROM {{ ref('stg_stock_prices') }})
    