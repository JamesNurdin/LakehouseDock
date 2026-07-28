WITH sales_with_promo AS (
  SELECT
    w.w_city AS warehouse_city,
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_net_profit,
    p.p_promo_name AS promo_name,
    i.i_product_name
  FROM web_sales ws
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE LOWER(i.i_product_name) LIKE '%coffee%'
    AND regexp_like(p.p_promo_name, '[0-9]{2,}')
)
SELECT
  warehouse_city,
  concat('Warehouse ', warehouse_city) AS warehouse_label,
  count(DISTINCT ws_order_number) AS orders,
  sum(ws_net_paid) AS total_net_paid,
  sum(ws_net_profit) AS total_net_profit,
  substring(promo_name, 1, 5) AS promo_prefix,
  regexp_extract(promo_name, '(\\d{2,})', 1) AS promo_number_extracted
FROM sales_with_promo
GROUP BY warehouse_city, promo_name
ORDER BY total_net_paid DESC
LIMIT 100
