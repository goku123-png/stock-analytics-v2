SELECT 'Monthly fact row count differs from intermediate' AS issue
WHERE
    (SELECT COUNT(*) FROM {{ ref('fct_monthly_stock') }})
    <>
    (SELECT COUNT(*) FROM {{ ref('int_monthly_stock_metrics') }})