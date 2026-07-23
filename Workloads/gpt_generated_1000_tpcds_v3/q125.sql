SELECT
  ws.ws_order_number AS order_number,
  d.d_date AS sales_date,
  ws.ws_ext_sales_price AS sales_amount,
  ws.ws_net_profit AS profit,
  p.p_promo_name AS source_name,
  wp.wp_url AS source_url,
  'Promotion' AS source_type
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2000
  AND p.p_promo_name LIKE '%Discount%'
  AND ws.ws_quantity > 0
UNION ALL
SELECT
  ws.ws_order_number AS order_number,
  d.d_date AS sales_date,
  ws.ws_ext_sales_price AS sales_amount,
  ws.ws_net_profit AS profit,
  cc.cc_name AS source_name,
  CAST(NULL AS varchar) AS source_url,
  'CallCenter' AS source_type
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cc.cc_division = 5
  AND ws.ws_quantity > 0
ORDER BY sales_date DESC, profit DESC
LIMIT 100
