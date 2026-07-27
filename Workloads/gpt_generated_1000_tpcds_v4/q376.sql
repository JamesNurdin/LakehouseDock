WITH store_sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_promo_sk,
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit,
        COUNT(*) AS store_txn_count
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_promo_sk, ss_customer_sk
),
catalog_sales_agg AS (
    SELECT
        cs_sold_date_sk,
        cs_promo_sk,
        cs_ship_mode_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs_net_profit) AS total_catalog_profit,
        COUNT(*) AS catalog_txn_count
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_promo_sk, cs_ship_mode_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    p.p_promo_name,
    sm.sm_type,
    wp.wp_url,
    sa.total_store_sales,
    ca.total_catalog_sales,
    (sa.total_store_sales + ca.total_catalog_sales) AS total_combined_sales,
    (sa.total_store_profit + ca.total_catalog_profit) AS total_combined_profit,
    RANK() OVER (PARTITION BY d.d_year ORDER BY (sa.total_store_sales + ca.total_catalog_sales) DESC) AS sales_rank,
    CASE
        WHEN (sa.total_store_sales + ca.total_catalog_sales) = 0 THEN 'No Sales'
        WHEN (sa.total_store_sales) / (sa.total_store_sales + ca.total_catalog_sales) > 0.5 THEN 'Store Dominant'
        ELSE 'Catalog Dominant'
    END AS sales_channel_category,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = p.p_promo_sk) AS max_promo_cost
FROM store_sales_agg sa
JOIN catalog_sales_agg ca
    ON sa.ss_sold_date_sk = ca.cs_sold_date_sk
    AND sa.ss_promo_sk = ca.cs_promo_sk
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c
    ON sa.ss_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    p.p_discount_active = 'N'
    AND p.p_channel_tv = 'N'
    AND sm.sm_type = 'AIR'
    AND wp.wp_link_count > 10
    AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_link_count > 20
    )
ORDER BY d.d_date ASC, sales_rank ASC
LIMIT 100
