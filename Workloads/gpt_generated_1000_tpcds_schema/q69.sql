WITH joined_data AS (
  SELECT
    i.i_category,
    i.i_color,
    ca_bill.ca_state,
    p.p_promo_name,
    cs.cs_net_paid,
    ws.ws_net_paid,
    cs.cs_order_number,
    ws.ws_order_number
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN customer_address ca_web ON ws.ws_bill_addr_sk = ca_web.ca_address_sk
  WHERE i.i_color = 'tan'
    AND ca_bill.ca_zip = '57783'
    AND p.p_channel_event = 'N'
    AND cs.cs_ext_sales_price > 2000
    AND ws.ws_net_paid_inc_tax < 500
)
SELECT
  i_category,
  i_color,
  ca_state,
  p_promo_name,
  SUM(cs_net_paid) AS total_catalog_net_paid,
  SUM(ws_net_paid) AS total_web_net_paid,
  COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
  COUNT(DISTINCT ws_order_number) AS web_order_cnt,
  ROW_NUMBER() OVER (ORDER BY SUM(cs_net_paid) + SUM(ws_net_paid) DESC) AS row_num
FROM joined_data
GROUP BY i_category, i_color, ca_state, p_promo_name
HAVING SUM(cs_net_paid) + SUM(ws_net_paid) > 10000
ORDER BY row_num
LIMIT 100
