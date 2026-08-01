WITH
    /* Sample a fraction of web_sales */
    ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE ws_sold_date_sk BETWEEN 2450000 AND 2453000
    ),
    /* Customers that placed bills */
    customer_bill AS (
        SELECT c_customer_sk,
               c_first_name,
               c_last_name,
               c_birth_month,
               c_preferred_cust_flag
        FROM customer
        WHERE c_birth_month IN (4, 6, 8)
    ),
    /* Filtered items */
    item_filt AS (
        SELECT i_item_sk,
               i_product_name,
               i_category,
               i_brand
        FROM item
        WHERE i_brand = 'Brand#12'
    ),
    /* Filtered promotions */
    promotion_filt AS (
        SELECT p_promo_sk,
               p_promo_name,
               p_channel_email,
               p_item_sk,
               p_discount_active
        FROM promotion
        WHERE p_channel_email = 'N'
          AND p_discount_active = 'Y'
    ),
    /* Filtered web sites */
    site_filt AS (
        SELECT web_site_sk,
               web_name,
               web_city,
               web_manager
        FROM web_site
        WHERE web_city IN ('Mount Zion', 'Georgetown')
    ),
    /* Orders with high net paid */
    high_value_orders AS (
        SELECT DISTINCT ws_order_number
        FROM ws_sample
        WHERE ws_net_paid > 1000
    ),
    /* Orders that used a clearance promotion */
    promo_orders AS (
        SELECT DISTINCT ws.ws_order_number
        FROM ws_sample ws
        JOIN promotion_filt p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE p.p_promo_name LIKE '%Clearance%'
    ),
    /* Intersection of the two order sets */
    common_orders AS (
        SELECT ws_order_number
        FROM high_value_orders
        INTERSECT
        SELECT ws_order_number
        FROM promo_orders
    ),
    /* Count promotions per item using a LATERAL sub‑query */
    item_with_promo AS (
        SELECT i.i_item_sk,
               i.i_product_name,
               i.i_category,
               p_cnt.promo_cnt
        FROM item_filt i
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS promo_cnt
            FROM promotion_filt p
            WHERE p.p_item_sk = i.i_item_sk
        ) p_cnt ON TRUE
    ),
    /* Main data set joining all five tables; promotion is joined with FULL OUTER JOIN */
    joined_data AS (
        SELECT ws.ws_order_number,
               ws.ws_sold_date_sk,
               ws.ws_net_paid,
               c.c_customer_sk,
               c.c_first_name,
               c.c_last_name,
               c.c_birth_month,
               i.i_product_name,
               i.i_category,
               p.p_promo_name,
               s.web_city,
               i.promo_cnt
        FROM ws_sample ws
        FULL OUTER JOIN promotion_filt p
            ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN customer_bill c
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN item_with_promo i
            ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN site_filt s
            ON ws.ws_web_site_sk = s.web_site_sk
        WHERE ws.ws_order_number IN (SELECT ws_order_number FROM common_orders)
    ),
    /* Small dimension for a CROSS JOIN */
    periods AS (
        SELECT 1 AS period UNION ALL SELECT 2 UNION ALL SELECT 3
    ),
    /* Aggregation with ROLLUP and a window ranking */
    final_agg AS (
        SELECT
            j.web_city,
            j.i_category,
            p.period,
            COUNT(DISTINCT j.ws_order_number) AS orders_cnt,
            SUM(j.ws_net_paid) AS total_net_paid,
            RANK() OVER (PARTITION BY j.web_city ORDER BY SUM(j.ws_net_paid) DESC) AS city_rank
        FROM joined_data j
        CROSS JOIN periods p
        GROUP BY ROLLUP (j.web_city, j.i_category, p.period)
    )
SELECT
    web_city,
    i_category,
    period,
    orders_cnt,
    total_net_paid,
    city_rank
FROM final_agg
ORDER BY web_city ASC NULLS LAST, total_net_paid DESC
LIMIT 100
