SELECT 'Daily fact row count differs from intermediate' AS issue

WHERE
    (
        SELECT COUNT(*)
        FROM {{ ref('fct_daily_stock') }}
    )
    <>
    (
        SELECT COUNT(*)
        FROM {{ ref('int_daily_stock_returns') }}
    )