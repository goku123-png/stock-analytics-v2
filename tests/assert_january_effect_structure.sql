WITH january AS (
    SELECT *
    FROM {{ ref('mart_january_effect') }}
)

SELECT stock_year_key AS issue
FROM january
GROUP BY stock_year_key
HAVING COUNT(*) > 1

UNION ALL

SELECT stock_year_key AS issue
FROM january
WHERE
    company_key IS NULL
    OR month_count <> 12
    OR valid_month_count <> 12
    OR january_return_pct IS NULL
    OR other_months_avg_return_pct IS NULL
    OR january_difference_pp IS NULL

UNION ALL

SELECT 'Expected 50 company-year rows' AS issue
WHERE (SELECT COUNT(*) FROM january) <> 50