WITH promo_filtered AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        p_discount_active,
        regexp_extract(p_promo_name, '(\\d+)%', 1) AS discount_pct
    FROM promotion
    WHERE regexp_like(p_promo_name, '[0-9]+%')
      AND p_discount_active = 'Y'
)
SELECT
    w.w_warehouse_name,
    pf.p_promo_name,
    pf.discount_pct,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    CASE
        WHEN wp.wp_type LIKE 'product%' THEN 'Product'
        ELSE 'Other'
    END AS page_category
FROM web_sales ws
JOIN promo_filtered pf ON ws.ws_promo_sk = pf.p_promo_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Good'
  AND w.w_gmt_offset = -5.00
  AND wp.wp_image_count >= 3
  AND wp.wp_url LIKE 'http://www.%'
GROUP BY
    w.w_warehouse_name,
    pf.p_promo_name,
    pf.discount_pct,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1),
    CASE
        WHEN wp.wp_type LIKE 'product%' THEN 'Product'
        ELSE 'Other'
    END
ORDER BY total_net_profit DESC
LIMIT 100
