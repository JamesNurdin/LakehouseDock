WITH sales_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        t.t_shift,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_shift = 'first'
      AND cs.cs_quantity > 1
    GROUP BY c.c_customer_sk, c.c_customer_id, t.t_shift
),
returns_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        t.t_shift,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_shift = 'first'
      AND wr.wr_return_amt > 0
    GROUP BY c.c_customer_sk, c.c_customer_id, t.t_shift
)
SELECT DISTINCT
    s.c_customer_id,
    s.t_shift,
    s.total_sales,
    s.sales_cnt,
    r.total_returns,
    r.returns_cnt
FROM sales_data s
LEFT JOIN returns_data r
    ON s.c_customer_sk = r.c_customer_sk
WHERE s.total_sales > (
    SELECT AVG(total_sales) FROM sales_data
)
UNION ALL
SELECT DISTINCT
    r.c_customer_id,
    r.t_shift,
    s.total_sales,
    s.sales_cnt,
    r.total_returns,
    r.returns_cnt
FROM returns_data r
LEFT JOIN sales_data s
    ON r.c_customer_sk = s.c_customer_sk
WHERE EXISTS (
    SELECT 1 FROM sales_data s2 WHERE s2.c_customer_sk = r.c_customer_sk AND s2.total_sales > 1000
)
ORDER BY total_sales DESC NULLS LAST, total_returns DESC NULLS LAST
LIMIT 100
