WITH cust_sales AS (
    SELECT
        c.c_customer_id,
        d_sales.d_date AS sales_date,
        c.c_first_sales_date_sk
    FROM customer c
    JOIN date_dim d_sales
        ON c.c_first_sales_date_sk = d_sales.d_date_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d_open.d_date AS open_date,
    d_closed.d_date AS closed_date,
    COUNT(DISTINCT cs.c_customer_id) AS customers_in_period,
    AVG(date_diff('day', d_open.d_date, cs.sales_date)) AS avg_days_to_first_sale,
    RANK() OVER (ORDER BY COUNT(DISTINCT cs.c_customer_id) DESC) AS popularity_rank
FROM call_center cc
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
LEFT JOIN cust_sales cs
    ON cs.sales_date BETWEEN d_open.d_date AND d_closed.d_date
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    d_open.d_date,
    d_closed.d_date
ORDER BY popularity_rank
LIMIT 10
