{{ config(materialized='table', schema='marts') }}

SELECT
    company_key,
    ticker,
    company_name
FROM (
    VALUES
        (1, 'AAPL', 'Apple'),
        (2, 'AMZN', 'Amazon'),
        (3, 'GOOGL', 'Alphabet'),
        (4, 'MSFT', 'Microsoft'),
        (5, 'NVDA', 'NVIDIA')
) AS companies(company_key, ticker, company_name)