WITH sales_agg AS (
    SELECT ss_customer_sk,
           SUM(ss_ext_sales_price) AS total_sales
    FROM store_sales
    GROUP BY ss_customer_sk
),
returns_agg_raw AS (
    SELECT wr_refunded_customer_sk AS customer_sk,
           SUM(wr_return_amt) AS total_return
    FROM web_returns
    WHERE wr_refunded_customer_sk IS NOT NULL
    GROUP BY wr_refunded_customer_sk
    UNION ALL
    SELECT wr_returning_customer_sk AS customer_sk,
           SUM(wr_return_amt) AS total_return
    FROM web_returns
    WHERE wr_returning_customer_sk IS NOT NULL
    GROUP BY wr_returning_customer_sk
),
returns_agg AS (
    SELECT customer_sk,
           SUM(total_return) AS total_return
    FROM returns_agg_raw
    GROUP BY customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_return, 0) AS total_return,
    COALESCE(s.total_sales, 0) - COALESCE(r.total_return, 0) AS net_revenue,
    CASE
        WHEN COALESCE(s.total_sales, 0) - COALESCE(r.total_return, 0) > 10000 THEN 'High'
        WHEN COALESCE(s.total_sales, 0) - COALESCE(r.total_return, 0) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category,
    RANK() OVER (ORDER BY COALESCE(s.total_sales, 0) - COALESCE(r.total_return, 0) DESC) AS revenue_rank
FROM customer c
LEFT JOIN sales_agg s
    ON c.c_customer_sk = s.ss_customer_sk
LEFT JOIN returns_agg r
    ON c.c_customer_sk = r.customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
ORDER BY revenue_rank
LIMIT 100
