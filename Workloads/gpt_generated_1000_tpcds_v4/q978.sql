WITH sales_by_year AS (
    SELECT 
        d.d_year AS year,
        'sales' AS metric_type,
        SUM(ws.ws_net_paid) AS total_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
    HAVING SUM(ws.ws_net_paid) > 10000
),
returns_by_year AS (
    SELECT 
        d.d_year AS year,
        'returns' AS metric_type,
        SUM(sr.sr_return_amt) AS total_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT year, metric_type, total_amount
FROM sales_by_year
UNION ALL
SELECT year, metric_type, total_amount
FROM returns_by_year
ORDER BY year, metric_type
LIMIT 100
