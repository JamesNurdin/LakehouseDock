WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        p.p_promo_name,
        sm.sm_ship_mode_id,
        sm.sm_code,
        wp.wp_url,
        d.d_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2000
      AND regexp_like(p.p_promo_name, '(?i)discount')
      AND wp.wp_url LIKE '%/product/%'
      AND regexp_like(wp.wp_url, '/product/[0-9]+')
)
SELECT
    sm_ship_mode_id,
    sm_code,
    CONCAT('Mode-', sm_code) AS mode_label,
    COUNT(DISTINCT ws_order_number) AS distinct_order_cnt,
    SUM(DISTINCT ws_ext_sales_price) AS distinct_sales_total,
    COUNT(DISTINCT p_promo_name) AS distinct_promo_cnt,
    MIN(p_promo_name) AS min_promo_name,
    SUBSTRING(MIN(p_promo_name) FROM 1 FOR 10) AS promo_name_prefix,
    MIN(regexp_extract(wp_url, '/product/([0-9]+)', 1)) AS sample_product_id
FROM filtered_sales
GROUP BY sm_ship_mode_id, sm_code
ORDER BY distinct_sales_total DESC
LIMIT 100
