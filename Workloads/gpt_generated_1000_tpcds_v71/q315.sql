WITH sales_customer AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_list_price,
        ss.ss_ext_discount_amt,
        c.c_birth_month,
        d.d_year,
        d.d_month_seq,
        d.d_dow
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1914               -- filter on fiscal year
      AND d.d_dow = 5                   -- filter on day of week (Saturday)
      AND ss.ss_list_price > 20.00     -- filter on relatively high list price
)
SELECT
    d_year,
    d_month_seq,
    CASE
        WHEN c_birth_month = 12 THEN 'December Birthday'
        WHEN c_birth_month = 1  THEN 'January Birthday'
        ELSE 'Other Birthday'
    END AS birth_month_group,
    COUNT(DISTINCT ss_customer_sk)                     AS unique_customers,
    SUM(ss_ext_sales_price)                           AS total_sales,
    AVG(ss_net_profit)                                AS avg_profit,
    MIN(ss_ext_sales_price)                           AS min_sales,
    MAX(ss_ext_sales_price)                           AS max_sales,
    (
        SELECT COUNT(DISTINCT ss2.ss_item_sk)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = sales_customer.d_year
    )                                                 AS distinct_items_sold_year
FROM sales_customer
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss3
    WHERE ss3.ss_customer_sk = sales_customer.ss_customer_sk
      AND ss3.ss_ext_discount_amt > 5.00               -- ensure the customer ever got a sizable discount
)
GROUP BY
    d_year,
    d_month_seq,
    CASE
        WHEN c_birth_month = 12 THEN 'December Birthday'
        WHEN c_birth_month = 1  THEN 'January Birthday'
        ELSE 'Other Birthday'
    END
ORDER BY total_sales DESC
LIMIT 100
