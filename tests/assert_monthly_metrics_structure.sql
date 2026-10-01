WITH monthly AS (
    SELECT *
    FROM {{ ref('int_monthly_stock_metrics') }}
)

SELECT stock_month_key AS issue
FROM monthly
GROUP BY stock_month_key
HAVING COUNT(*) > 1

UNION ALL

SELECT stock_month_key AS issue
FROM monthly
WHERE
    stock_month_key IS NULL
    OR trading_days < 1
    OR valid_return_days <> trading_days
        - CASE
            WHEN month_start = DATE '2015-01-01'
            THEN 1 ELSE 0
          END
    OR (
        month_start = DATE '2015-01-01'
        AND monthly_return_pct IS NOT NULL
    )
    OR (
        month_start > DATE '2015-01-01'
        AND monthly_return_pct IS NULL
    )

UNION ALL

SELECT 'Monthly trading days differ from daily rows' AS issue
WHERE
    (SELECT SUM(trading_days) FROM monthly)
    <>
    (
        SELECT COUNT(*)
        FROM {{ ref('int_daily_stock_returns') }}
    )