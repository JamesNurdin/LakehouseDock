WITH avg_profit AS (
    SELECT AVG(ws2.ws_net_profit) AS avg_net_profit
    FROM web_sales ws2
)
SELECT
    i.i_brand,
    i.i_category,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(ws.ws_net_profit) > (SELECT avg_net_profit FROM avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE REGEXP_LIKE(wp.wp_url, '^https?://.*example\\.com')
  AND i.i_product_name LIKE '%Premium%'
  AND SUBSTRING(i.i_color, 1, 1) = 'R'
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ws.ws_promo_sk
          AND p.p_discount_active = 'Y'
    )
GROUP BY i.i_brand, i.i_category, i.i_product_name,
         REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1)
HAVING COUNT(*) > 10
ORDER BY total_profit DESC
LIMIT 100
