WITH
    brand800_customers AS (
        SELECT DISTINCT ss.ss_customer_sk
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE i.i_brand_id = 8007005
          AND ss.ss_ext_sales_price > 100
    ),
    brand700_customers AS (
        SELECT DISTINCT ss.ss_customer_sk
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE i.i_brand_id = 7004003
          AND ss.ss_ext_sales_price > 100
    ),
    target_customers AS (
        SELECT ss_customer_sk
        FROM brand800_customers
        EXCEPT
        SELECT ss_customer_sk
        FROM brand700_customers
    ),
    raw_sales AS (
        SELECT
            ss.ss_customer_sk,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            ss.ss_item_sk,
            ss.ss_sold_date_sk,
            ss.ss_ext_sales_price,
            ss.ss_coupon_amt
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE ss.ss_customer_sk IN (SELECT ss_customer_sk FROM target_customers)
          AND c.c_current_cdemo_sk IN (1168667, 1473522)
          AND ss.ss_coupon_amt > 300
    ),
    agg_sales AS (
        SELECT
            rs.ss_customer_sk,
            rs.c_customer_id,
            rs.c_first_name,
            rs.c_last_name,
            COUNT(DISTINCT rs.ss_item_sk) AS distinct_item_count,
            SUM(DISTINCT rs.ss_ext_sales_price) AS distinct_sales_sum,
            SUM(rs.ss_ext_sales_price) AS total_sales,
            MAX(rs.ss_sold_date_sk) AS last_sold_date_sk
        FROM raw_sales rs
        GROUP BY
            rs.ss_customer_sk,
            rs.c_customer_id,
            rs.c_first_name,
            rs.c_last_name
    )
SELECT
    a.c_customer_id,
    a.c_first_name,
    a.c_last_name,
    a.distinct_item_count,
    a.distinct_sales_sum,
    a.total_sales,
    SUM(a.total_sales) OVER (PARTITION BY a.ss_customer_sk ORDER BY a.last_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
    LAG(a.total_sales) OVER (PARTITION BY a.ss_customer_sk ORDER BY a.last_sold_date_sk) AS previous_total_sales,
    (SELECT COUNT(DISTINCT c3.c_customer_sk) FROM customer c3) AS total_customers_all
FROM agg_sales a
ORDER BY running_total_sales DESC, a.c_customer_id
LIMIT 100
