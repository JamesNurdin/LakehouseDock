WITH promo_sales AS (
    SELECT
        w.w_warehouse_name,
        'PROMO' AS sale_type,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_max_ad_count > 1
      )
    GROUP BY w.w_warehouse_name
),
non_promo_sales AS (
    SELECT
        w.w_warehouse_name,
        'NON_PROMO' AS sale_type,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE (p.p_promo_sk IS NULL OR p.p_discount_active <> 'Y')
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_max_ad_count = 0
      )
    GROUP BY w.w_warehouse_name
)
SELECT *
FROM promo_sales
UNION ALL
SELECT *
FROM non_promo_sales
ORDER BY sale_type, total_profit DESC
LIMIT 100
