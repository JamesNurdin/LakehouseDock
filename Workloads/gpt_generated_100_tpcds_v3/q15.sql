WITH joined_data AS (
  SELECT
    cc.cc_call_center_id,
    w.w_warehouse_name,
    i.i_item_id,
    t.t_shift,
    r.r_reason_desc,
    cs.cs_net_paid,
    ss.ss_net_paid,
    ws.ws_net_paid,
    cr.cr_net_loss,
    inv.inv_quantity_on_hand,
    cs.cs_order_number,
    i.i_current_price,
    t.t_hour
  FROM tpcds.time_dim t
  JOIN tpcds.store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN tpcds.item i
    ON i.i_item_sk = ss.ss_item_sk
   AND i.i_item_sk = cs.cs_item_sk
   AND i.i_item_sk = ws.ws_item_sk
  JOIN tpcds.warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
   AND w.w_warehouse_sk = ws.ws_warehouse_sk
  JOIN tpcds.call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
  JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_returned_time_sk = t.t_time_sk
  JOIN tpcds.reason r
    ON r.r_reason_sk = cr.cr_reason_sk
  WHERE cc.cc_company = 2
    AND cc.cc_sq_ft > 400000000
    AND w.w_state = 'CA'
    AND i.i_brand = 'BrandX'
    AND t.t_shift = 'first'
)
SELECT
  cc_call_center_id,
  w_warehouse_name,
  i_item_id,
  t_shift,
  r_reason_desc,
  SUM(cs_net_paid) AS total_catalog_sales,
  SUM(ss_net_paid) AS total_store_sales,
  SUM(ws_net_paid) AS total_web_sales,
  SUM(cr_net_loss) AS total_return_loss,
  SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
  COUNT(DISTINCT cs_order_number) AS distinct_orders,
  AVG(i_current_price) AS avg_item_price,
  MIN(t_hour) AS min_hour,
  MAX(t_hour) AS max_hour
FROM joined_data
GROUP BY
  cc_call_center_id,
  w_warehouse_name,
  i_item_id,
  t_shift,
  r_reason_desc
ORDER BY total_catalog_sales DESC
LIMIT 100
