WITH store_sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        'sales' AS metric_type,
        SUM(ss.ss_ext_sales_price) AS amount,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 1000 THEN 'HIGH' ELSE 'LOW' END AS category
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id
),
web_returns_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        'returns' AS metric_type,
        SUM(wr.wr_return_amt) AS amount,
        CASE WHEN SUM(wr.wr_return_amt) > 500 THEN 'HIGH' ELSE 'LOW' END AS category
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id
)
SELECT *
FROM store_sales_agg
UNION ALL
SELECT *
FROM web_returns_agg
ORDER BY amount DESC, customer_id
LIMIT 100
