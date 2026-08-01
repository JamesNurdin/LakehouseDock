SELECT
  cp.cp_department,
  wp.wp_type,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(ws.ws_net_paid) AS total_web_sales,
  SUM(cr.cr_return_amount) AS total_catalog_returns,
  SUM(wr.wr_return_amt) AS total_web_returns,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
  COUNT(DISTINCT st.s_store_sk) AS stores_closed_count,
  (SELECT AVG(inv2.inv_quantity_on_hand) FROM inventory inv2) AS avg_inventory_all
FROM date_dim d
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_item_sk = cs.cs_item_sk
  AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
JOIN store st
  ON st.s_closed_date_sk = d.d_date_sk
WHERE
  d.d_year = 2000
  AND cp.cp_department = 'Books'
  AND sm.sm_type = 'AIR'
  AND inv.inv_quantity_on_hand > 500
  AND wp.wp_type = 'content'
GROUP BY ROLLUP (cp.cp_department, wp.wp_type)
HAVING
  SUM(inv.inv_quantity_on_hand) > (SELECT AVG(inv2.inv_quantity_on_hand) FROM inventory inv2) * 2
ORDER BY total_catalog_sales DESC
LIMIT 100
