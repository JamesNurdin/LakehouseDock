SELECT
  sub.i_category,
  sub.warehouse_state,
  sub.ship_mode_type,
  COUNT(DISTINCT sub.cs_order_number) AS num_orders,
  SUM(sub.cs_ext_sales_price) AS total_sales,
  SUM(sub.cs_net_profit) AS total_profit,
  AVG(sub.cs_ext_discount_amt) AS avg_discount,
  SUM(sub.sr_return_amt) AS total_store_returns,
  SUM(sub.wr_return_amt) AS total_web_returns,
  SUM(sub.inv_quantity_on_hand) AS total_inventory_on_hand
FROM (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    i.i_category,
    w.w_state AS warehouse_state,
    sm.sm_type AS ship_mode_type,
    sr.sr_return_amt,
    wr.wr_return_amt,
    inv.inv_quantity_on_hand,
    cc.cc_state,
    td.t_hour,
    p.p_discount_active
  FROM tpcds.catalog_sales cs
  JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  LEFT JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN tpcds.reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
  LEFT JOIN tpcds.reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE cc.cc_state = 'CA'
    AND w.w_state = 'TX'
    AND i.i_category = 'Sports'
    AND sm.sm_type = 'AIR'
    AND p.p_discount_active = 'Y'
    AND td.t_hour BETWEEN 9 AND 11
) sub
GROUP BY sub.i_category, sub.warehouse_state, sub.ship_mode_type
ORDER BY total_sales DESC
LIMIT 100
