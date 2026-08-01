WITH
    item_promo_full AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_color,
            p.p_promo_sk,
            p.p_promo_name,
            p.p_discount_active
        FROM item i
        FULL OUTER JOIN promotion p
            ON i.i_item_sk = p.p_item_sk
    ),
    customer_sales AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            s.s_store_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            COUNT(DISTINCT ss.ss_item_sk) AS distinct_items
        FROM store_sales ss
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        GROUP BY
            c.c_customer_sk,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            s.s_store_sk
    ),
    stores_without_sales AS (
        SELECT s_store_sk
        FROM store
        EXCEPT
        SELECT DISTINCT ss_store_sk
        FROM store_sales
    )
SELECT
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    cs.total_sales,
    cs.distinct_items,
    (
        SELECT COUNT(*)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cs.c_customer_sk
          AND ss2.ss_net_paid > 100
    ) AS high_value_txn_count,
    RANK() OVER (PARTITION BY cs.s_store_sk ORDER BY cs.total_sales DESC) AS sales_rank_in_store,
    COUNT(DISTINCT ip.i_color) AS distinct_colors_bought,
    COUNT(DISTINCT ip.p_promo_name) FILTER (WHERE ip.p_promo_name IS NOT NULL) AS distinct_promos_used,
    SUBSTRING(ip.i_product_name FROM 1 FOR 5) AS product_name_prefix,
    ip.p_promo_name
FROM customer_sales cs
LEFT JOIN store_sales ss
    ON ss.ss_customer_sk = cs.c_customer_sk
LEFT JOIN item_promo_full ip
    ON ss.ss_item_sk = ip.i_item_sk
WHERE
    cs.c_last_name LIKE 'S%'
    AND REGEXP_LIKE(cs.c_first_name, '^[A-M].*')
    AND ip.i_color IS NOT NULL
    AND REGEXP_LIKE(ip.i_color, '^[a-z]+$')
    AND ip.p_promo_name IS NOT NULL
    AND REGEXP_LIKE(ip.p_promo_name, '^.{3,}')
    AND ip.i_product_name LIKE '%-%'
GROUP BY
    cs.c_customer_sk,
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.s_store_sk,
    cs.total_sales,
    cs.distinct_items,
    ip.p_promo_name,
    ip.i_product_name
ORDER BY cs.total_sales DESC, full_name
LIMIT 100
