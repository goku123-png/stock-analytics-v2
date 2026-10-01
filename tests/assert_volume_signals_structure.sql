WITH signals AS (
    SELECT *
    FROM {{ ref('int_monthly_volume_signals') }}
)

SELECT stock_month_key AS issue
FROM signals
GROUP BY stock_month_key
HAVING COUNT(*) > 1

UNION ALL

SELECT stock_month_key AS issue
FROM signals
WHERE
    (
        baseline_months < 12
        AND (
            volume_ratio IS NOT NULL
            OR volume_group IS NOT NULL
        )
    )
    OR (
        baseline_months = 12
        AND (
            volume_ratio IS NULL
            OR volume_group IS NULL
        )
    )

UNION ALL

SELECT 'Volume signals row count differs from monthly metrics' AS issue
WHERE
    (SELECT COUNT(*) FROM signals)
    <>
    (
        SELECT COUNT(*)
        FROM {{ ref('int_monthly_stock_metrics') }}
    )