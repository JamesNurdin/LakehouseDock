-- Goal: compare total sales per customer across catalog and web channels, keep customers that appear in only one channel, list individual sale amounts with ranking and show previous total
WITH catalog_lines AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_ext_sales_price AS sales_amount,
        t.t_hour
    FROM catalog_sales cs
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour < 12
),
web_lines AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_ext_sales_price AS sales_amount,
        t.t_hour
    FROM web_sales ws
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour >= 12
),
combined_lines AS (
    SELECT * FROM catalog_lines
    UNION ALL
    SELECT * FROM web_lines
),
customer_agg AS (
    SELECT
        cl.customer_sk,
        SUM(cl.sales_amount) AS total_sales,
        ARRAY_AGG(cl.sales_amount) AS sales_array
    FROM combined_lines cl
    GROUP BY cl.customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
    FROM customer c
),
full_data AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ca.total_sales,
        ca.sales_array
    FROM customer_info ci
    FULL OUTER JOIN customer_agg ca
      ON ci.c_customer_sk = ca.customer_sk
)
SELECT
    fd.c_customer_sk,
    fd.c_first_name,
    fd.c_last_name,
    COALESCE(fd.total_sales, 0) AS total_sales,
    lag(COALESCE(fd.total_sales, 0)) OVER (ORDER BY COALESCE(fd.total_sales, 0) DESC) AS prior_total_sales,
    sales_detail.sales_amount,
    ROW_NUMBER() OVER (PARTITION BY fd.c_customer_sk ORDER BY sales_detail.sales_amount DESC) AS sales_rank
FROM full_data fd
LEFT JOIN LATERAL (
    SELECT val AS sales_amount
    FROM UNNEST(COALESCE(fd.sales_array, ARRAY[CAST(NULL AS decimal(7,2))])) AS t(val)
) AS sales_detail ON TRUE
ORDER BY total_sales DESC
LIMIT 100
