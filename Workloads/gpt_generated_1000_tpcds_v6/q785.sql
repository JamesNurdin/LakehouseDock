WITH sales_returns AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d_sales.d_year AS year,
        i.i_category AS category,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d_sales.d_year = 2001
      AND c.c_birth_country = 'CHILE'
      AND s.s_country = 'United States'
      AND i.i_category = 'Sports'
      AND wr.wr_return_quantity > 10
    GROUP BY s.s_store_id, s.s_store_name, d_sales.d_year, i.i_category
)
SELECT
    store_id,
    store_name,
    year,
    category,
    distinct_customers,
    total_sales,
    total_profit,
    total_return_amount,
    total_return_qty,
    SUM(total_sales) OVER (PARTITION BY store_name ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_store
FROM sales_returns
ORDER BY total_sales DESC
LIMIT 100
