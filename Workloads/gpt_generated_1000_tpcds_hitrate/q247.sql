WITH filtered_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_manufact,
           i_class,
           i_category,
           i_current_price
    FROM item
    WHERE regexp_like(i_manufact, '^a.*t$')
)
SELECT ws.ws_web_site_sk,
       ws_site.web_market_manager,
       COUNT(DISTINCT ws.ws_order_number) AS orders,
       SUM(ws.ws_net_paid) AS total_net_paid,
       AVG(ws.ws_quantity) AS avg_qty,
       CONCAT('Mgr: ', ws_site.web_market_manager) AS manager_label,
       regexp_extract(ws_site.web_mkt_desc, '(\\w+)') AS first_word_desc
FROM web_sales ws
JOIN filtered_items fi
  ON ws.ws_item_sk = fi.i_item_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
WHERE ws_site.web_market_manager LIKE '%John%'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = fi.i_item_sk
          AND cr.cr_return_quantity > 0
      )
GROUP BY ws.ws_web_site_sk,
         ws_site.web_market_manager,
         ws_site.web_mkt_desc,
         regexp_extract(ws_site.web_mkt_desc, '(\\w+)')
ORDER BY total_net_paid DESC
LIMIT 100
