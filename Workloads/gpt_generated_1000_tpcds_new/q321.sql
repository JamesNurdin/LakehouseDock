WITH
  cr_agg AS (
    SELECT
      cr_item_sk,
      cr_reason_sk,
      cr_order_number,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(cr_return_quantity) AS total_return_qty
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY cr_item_sk, cr_reason_sk, cr_order_number
  ),
  reason_subset AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%customer%'
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  p.p_promo_name,
  rs.r_reason_desc,
  const_set.analysis_date,
  SUM(cs.cs_net_profit) AS catalog_net_profit,
  SUM(ss.ss_net_profit) AS store_net_profit,
  SUM(ws.ws_net_profit) AS web_net_profit,
  SUM(cr_agg.total_return_amount) AS total_return_amount,
  SUM(inv.inv_quantity_on_hand) AS total_on_hand
FROM cr_agg
JOIN catalog_sales cs
  ON cs.cs_item_sk = cr_agg.cr_item_sk
 AND cs.cs_order_number = cr_agg.cr_order_number
JOIN item i
  ON i.i_item_sk = cr_agg.cr_item_sk
JOIN promotion p
  ON p.p_promo_sk = cs.cs_promo_sk
JOIN call_center cc
  ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN time_dim t
  ON t.t_time_sk = cs.cs_sold_time_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = i.i_item_sk
JOIN reason_subset rs
  ON rs.r_reason_sk = sr.sr_reason_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
  ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
CROSS JOIN (SELECT DATE '2023-01-01' AS analysis_date) const_set
WHERE
  t.t_am_pm = 'PM'
  AND i.i_current_price > 100
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND hd.hd_vehicle_count >= 1
GROUP BY
  i.i_item_id,
  i.i_product_name,
  p.p_promo_name,
  rs.r_reason_desc,
  const_set.analysis_date
ORDER BY total_return_amount DESC
LIMIT 100
