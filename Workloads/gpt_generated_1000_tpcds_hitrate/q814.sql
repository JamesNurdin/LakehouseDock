WITH
    -- First sub‑query with catalog channel and preferred customers
    src_a AS (
        SELECT
            p.p_promo_id AS promo_id,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            (
                SELECT SUM(ss2.ss_net_profit)
                FROM store_sales ss2
                WHERE ss2.ss_customer_sk = ss.ss_customer_sk
            ) AS customer_total_profit
        FROM store_sales ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE ss.ss_ext_sales_price > (
                SELECT MAX(ss3.ss_ext_sales_price)
                FROM store_sales ss3
                WHERE ss3.ss_quantity > 10
            )
          AND ss.ss_customer_sk IN (
                SELECT c2.c_customer_sk
                FROM customer c2
                WHERE c2.c_preferred_cust_flag = 'Y'
            )
          AND p.p_channel_catalog = 'N'
        GROUP BY p.p_promo_id, ss.ss_customer_sk
    ),
    -- Second sub‑query with email channel and low total sales
    src_b AS (
        SELECT
            p.p_promo_id AS promo_id,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            (
                SELECT SUM(ss2.ss_net_profit)
                FROM store_sales ss2
                WHERE ss2.ss_customer_sk = ss.ss_customer_sk
            ) AS customer_total_profit
        FROM store_sales ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE p.p_channel_email = 'Y'
          AND ss.ss_quantity BETWEEN 1 AND 5
        GROUP BY p.p_promo_id, ss.ss_customer_sk
        HAVING SUM(ss.ss_ext_sales_price) < (
                SELECT MIN(ss4.ss_ext_sales_price)
                FROM store_sales ss4
            )
    ),
    -- Set of promotions to be excluded (purpose = 'Unknown')
    src_exclude AS (
        SELECT
            p.p_promo_id AS promo_id,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            CAST(NULL AS decimal(15,2)) AS customer_total_profit
        FROM store_sales ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE p.p_purpose = 'Unknown'
        GROUP BY p.p_promo_id
    ),
    -- Union of the two source sets
    united AS (
        SELECT promo_id, total_sales, customer_total_profit FROM src_a
        UNION ALL
        SELECT promo_id, total_sales, customer_total_profit FROM src_b
    )
SELECT promo_id, total_sales, customer_total_profit
FROM united
EXCEPT
SELECT promo_id, total_sales, customer_total_profit FROM src_exclude
ORDER BY total_sales DESC
LIMIT 100
