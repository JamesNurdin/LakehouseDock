WITH
  catalog_items AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
  ),
  store_items AS (
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM store_sales ss
  ),
  web_items AS (
    SELECT DISTINCT ws.ws_item_sk AS item_sk
    FROM web_sales ws
  ),
  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      i.i_category,
      i.i_brand,
      w.w_state,
      ca.ca_city,
      r.r_reason_desc,
      CASE WHEN cs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
      cc.cc_name AS call_center_name,
      inv.inv_quantity_on_hand,
      ws.ws_order_number AS ws_order_number,
      wp.wp_url,
      we.web_name AS web_site_name,
      ss.ss_ticket_number AS store_ticket_number,
      i2.i_brand AS secondary_brand,
      w2.w_city AS secondary_warehouse_city
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
                             AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk AND i2.i_brand = 'SpecificBrand'
    LEFT JOIN warehouse w2 ON cs.cs_warehouse_sk = w2.w_warehouse_sk AND w2.w_state = 'CA'
  )
SELECT
  i_category,
  i_brand,
  w_state,
  ca_city,
  r_reason_desc,
  profit_level,
  SUM(cs_net_paid) AS total_net_paid,
  SUM(cs_net_profit) AS total_net_profit,
  COUNT(DISTINCT cs_order_number) AS order_cnt,
  (SELECT COUNT(*) FROM catalog_items
   EXCEPT
   SELECT * FROM store_items) AS items_in_catalog_not_in_store,
  (SELECT COUNT(*) FROM catalog_items
   INTERSECT
   SELECT * FROM web_items) AS items_in_both_catalog_and_web
FROM base
GROUP BY CUBE (i_category, i_brand, w_state, ca_city, r_reason_desc, profit_level)
HAVING SUM(cs_net_profit) > 0
ORDER BY total_net_paid DESC
LIMIT 100
