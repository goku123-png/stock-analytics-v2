{{ config(materialized='view', schema='intermediate') }}

WITH baseline AS (
    SELECT
        *,
        COUNT(avg_daily_volume) OVER (
            PARTITION BY ticker
            ORDER BY month_start
            ROWS BETWEEN 12 PRECEDING AND 1 PRECEDING
        ) AS baseline_months,

        AVG(avg_daily_volume) OVER (
            PARTITION BY ticker
            ORDER BY month_start
            ROWS BETWEEN 12 PRECEDING AND 1 PRECEDING
        ) AS baseline_avg_daily_volume

    FROM {{ ref('int_monthly_stock_metrics') }}
),

ratios AS (
    SELECT
        *,
        CASE
            WHEN baseline_months = 12
            THEN avg_daily_volume
                / NULLIF(baseline_avg_daily_volume, 0)
        END AS volume_ratio

    FROM baseline
)

SELECT
    b.*,

    CASE
        WHEN b.volume_ratio IS NULL THEN NULL
        WHEN b.volume_ratio >= 1.5 THEN 'Spike'
        WHEN b.volume_ratio >= 1.0 THEN 'Normal'
        ELSE 'Low'
    END AS volume_group,

    (
        f1.month_end_close
        / NULLIF(b.month_end_close, 0) - 1
    ) * 100 AS forward_1m_return_pct,

    (
        f3.month_end_close
        / NULLIF(b.month_end_close, 0) - 1
    ) * 100 AS forward_3m_return_pct

FROM ratios AS b

LEFT JOIN {{ ref('int_monthly_stock_metrics') }} AS f1
    ON b.ticker = f1.ticker
    AND f1.month_start = b.month_start + INTERVAL '1 month'

LEFT JOIN {{ ref('int_monthly_stock_metrics') }} AS f3
    ON b.ticker = f3.ticker
    AND f3.month_start = b.month_start + INTERVAL '3 months'