WITH
  inv_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  avg_qty AS (
    SELECT avg(cs_quantity) AS avg_qty FROM catalog_sales
  )
SELECT
  s.s_store_name,
  i.i_category,
  SUM(cs.cs_sales_price)               AS total_catalog_sales,
  SUM(ss.ss_quantity)                 AS total_store_quantity,
  SUM(ws.ws_quantity)                 AS total_web_quantity,
  SUM(ws.ws_net_profit)               AS total_web_profit,
  SUM(inv.inv_quantity_on_hand)       AS total_inventory_on_hand,
  SUM(CASE WHEN cs.cs_quantity > (SELECT avg_qty FROM avg_qty) THEN 1 ELSE 0 END) AS cnt_above_avg_qty
FROM catalog_sales cs
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer cust_bill
  ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer cust_ship
  ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN inv_sample inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
 AND ss.ss_sold_time_sk = t.t_time_sk
RIGHT OUTER JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
      )
GROUP BY ROLLUP (s.s_store_name, i.i_category)
ORDER BY s.s_store_name, i.i_category
LIMIT 100
