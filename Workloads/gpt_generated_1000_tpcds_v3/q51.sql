WITH base AS (
  SELECT
    s.s_store_name,
    we.web_name,
    i.i_category,
    i.i_brand,
    cc.cc_name,
    cs.cs_net_paid,
    ws.ws_net_paid,
    sr.sr_net_loss,
    cs.cs_quantity,
    ws.ws_quantity,
    i.i_item_sk
  FROM item i
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
  WHERE ca_cs.ca_state = 'CA'
    AND w.w_zip = '78370'
    AND p.p_discount_active = 'Y'
    AND we.web_company_id = 2
    AND i.i_category = 'Electronics'
    AND i.i_color = 'Red'
)
SELECT
  s_store_name,
  web_name,
  i_category,
  i_brand,
  cc_name,
  SUM(cs_net_paid) AS total_catalog_net_paid,
  SUM(ws_net_paid) AS total_web_net_paid,
  SUM(sr_net_loss) AS total_store_returns_loss,
  COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
  AVG(cs_quantity) AS avg_catalog_quantity,
  AVG(ws_quantity) AS avg_web_quantity,
  (
    SELECT AVG(cs2.cs_net_profit)
    FROM catalog_sales cs2
    JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
    WHERE i2.i_category = base.i_category
  ) AS avg_category_net_profit
FROM base
GROUP BY
  s_store_name,
  web_name,
  i_category,
  i_brand,
  cc_name
ORDER BY (SUM(cs_net_paid) + SUM(ws_net_paid)) DESC
LIMIT 100
