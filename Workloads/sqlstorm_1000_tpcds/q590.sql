WITH sales AS (
  SELECT
    ss_sold_date_sk AS date_sk,
    ss_item_sk AS item_sk,
    ss_store_sk AS org_sk,
    ss_promo_sk AS promo_sk,
    ss_quantity AS quantity,
    ss_net_paid AS net_paid,
    ss_net_profit AS net_profit,
    'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT
    cs_sold_date_sk,
    cs_item_sk,
    cs_call_center_sk,
    cs_promo_sk,
    cs_quantity,
    cs_net_paid,
    cs_net_profit,
    'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT
    ws_sold_date_sk,
    ws_item_sk,
    ws_warehouse_sk,
    ws_promo_sk,
    ws_quantity,
    ws_net_paid,
    ws_net_profit,
    'web' AS channel
  FROM web_sales
)
SELECT
  d.d_year,
  p.p_promo_name,
  s.channel,
  i.i_category,
  i.i_brand,
  SUM(s.net_paid) AS total_sales,
  SUM(s.net_profit) AS total_profit,
  COUNT(*) AS transactions
FROM sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
LEFT JOIN store st ON s.channel = 'store' AND st.s_store_sk = s.org_sk
LEFT JOIN call_center cc ON s.channel = 'catalog' AND cc.cc_call_center_sk = s.org_sk
LEFT JOIN warehouse wh ON s.channel = 'web' AND wh.w_warehouse_sk = s.org_sk
GROUP BY
  d.d_year,
  p.p_promo_name,
  s.channel,
  i.i_category,
  i.i_brand
ORDER BY
  d.d_year,
  total_sales DESC
LIMIT 200
