WITH
  sampled_catalog_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  valid_orders AS (
    SELECT cs_order_number
    FROM sampled_catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  ),
  store_sales_alias AS (
    SELECT *
    FROM store_sales
  ),
  item_dim2 AS (
    SELECT i_item_sk AS dim2_item_sk,
           i_category AS dim2_category
    FROM item
  ),
  item_with_array AS (
    SELECT i_item_sk,
           ARRAY[ i_item_sk, i_item_sk + 1 ] AS item_pair
    FROM item
  )
SELECT
  cp.cp_department,
  i.i_category,
  ib.ib_lower_bound,
  SUM(cs.cs_ext_sales_price)                         AS total_catalog_sales,
  SUM(ss.ss_net_paid)                               AS total_store_sales,
  SUM(ws.ws_net_paid)                               AS total_web_sales,
  COUNT(DISTINCT cs.cs_order_number)                AS catalog_orders,
  CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_volume_flag,
  t.item_id
FROM sampled_catalog_sales cs
JOIN valid_orders vo ON cs.cs_order_number = vo.cs_order_number
JOIN item i ON cs.cs_item_sk = i.i_item_sk
FULL OUTER JOIN store_sales_alias ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND w.w_warehouse_sk = inv.inv_warehouse_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN item_dim2 id2 ON id2.dim2_item_sk = ws.ws_item_sk
JOIN item_with_array iwa ON iwa.i_item_sk = i.i_item_sk
CROSS JOIN UNNEST(iwa.item_pair) AS t(item_id)
WHERE cp.cp_department = 'Books'
  AND td_cs.t_hour BETWEEN 9 AND 17
GROUP BY cp.cp_department,
         i.i_category,
         ib.ib_lower_bound,
         t.item_id
HAVING COUNT(*) > 10
ORDER BY total_catalog_sales DESC
LIMIT 100
