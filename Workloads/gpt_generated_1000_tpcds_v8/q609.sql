WITH
    -- Aggregate sales with first set of filters
    agg_a AS (
        SELECT
            ss_customer_sk,
            SUM(ss_ext_sales_price) AS sales_a,
            SUM(ss_net_profit)       AS profit_a,
            COUNT(*)                AS cnt_a
        FROM store_sales
        WHERE ss_sold_date_sk >= 2451124
          AND ss_sold_date_sk <= 2452158
          AND ss_quantity    > 1
          AND ss_ext_list_price > 100.00
        GROUP BY ss_customer_sk
    ),
    -- Aggregate sales with a second, different set of filters
    agg_b AS (
        SELECT
            ss_customer_sk,
            SUM(ss_ext_sales_price) AS sales_b,
            SUM(ss_net_profit)       AS profit_b,
            COUNT(*)                AS cnt_b
        FROM store_sales
        WHERE ss_sold_date_sk >= 2451448
          AND ss_sold_date_sk <= 2452596
          AND ss_quantity    <= 5
          AND ss_ext_discount_amt > 0
        GROUP BY ss_customer_sk
    ),
    -- Union the two aggregated result sets (deduplication enforced by UNION)
    union_sales AS (
        SELECT ss_customer_sk, sales_a AS total_sales, profit_a AS total_profit, cnt_a AS sales_cnt
        FROM agg_a
        UNION
        SELECT ss_customer_sk, sales_b, profit_b, cnt_b
        FROM agg_b
    ),
    -- Intersect customer keys that satisfy two independent conditions
    intersect_keys AS (
        SELECT ss_customer_sk FROM store_sales WHERE ss_quantity >= 2
        INTERSECT
        SELECT c_customer_sk FROM customer WHERE c_birth_month = 5
    ),
    -- Join customers to the unioned sales and apply additional filters / anti‑join
    joined AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            us.total_sales,
            us.total_profit,
            us.sales_cnt,
            CASE WHEN us.total_sales > 5000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
            -- Correlated scalar subquery: total discount per customer
            (SELECT COALESCE(SUM(s2.ss_ext_discount_amt), 0)
             FROM store_sales s2
             WHERE s2.ss_customer_sk = c.c_customer_sk) AS total_discount
        FROM customer c
        JOIN union_sales us
            ON c.c_customer_sk = us.ss_customer_sk
        WHERE c.c_customer_sk IN (SELECT ss_customer_sk FROM intersect_keys)
          AND NOT EXISTS (
                SELECT 1
                FROM store_sales s3
                WHERE s3.ss_customer_sk = c.c_customer_sk
                  AND s3.ss_net_paid > 20000
          )
          AND c.c_preferred_cust_flag = 'Y'
          AND c.c_birth_year BETWEEN 1960 AND 1980
    )
SELECT
    sales_category,
    COUNT(*)                     AS customer_count,
    AVG(total_sales)             AS avg_total_sales,
    SUM(total_discount)          AS sum_total_discount
FROM joined
GROUP BY sales_category
HAVING COUNT(*) >= 2
ORDER BY avg_total_sales DESC
LIMIT 100
