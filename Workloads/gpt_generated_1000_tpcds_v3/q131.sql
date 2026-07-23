SELECT
  d.d_year,
  d.d_month_seq,
  cc.cc_name,
  p.p_promo_name,
  sm.sm_type,
  w.w_state,
  cd.cd_gender,
  SUM(cs.cs_net_paid) AS total_sales_net,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(ss.ss_net_paid) AS total_store_sales_net,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  AVG(cs.cs_quantity) AS avg_cs_quantity,
  MIN(cs.cs_net_paid) AS min_cs_net_paid,
  MAX(cs.cs_net_paid) AS max_cs_net_paid
FROM
  catalog_sales cs
  INNER JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  INNER JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  INNER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  INNER JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  INNER JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_returned_date_sk = d.d_date_sk
       AND cr.cr_returned_time_sk = t.t_time_sk
  LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
       AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_sold_time_sk = t.t_time_sk
       AND ss.ss_cdemo_sk = cd.cd_demo_sk
       AND ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE
  d.d_year = 2001
  AND t.t_hour BETWEEN 9 AND 17
  AND cc.cc_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'TX'
  AND inv.inv_quantity_on_hand > 500
GROUP BY
  d.d_year,
  d.d_month_seq,
  cc.cc_name,
  p.p_promo_name,
  sm.sm_type,
  w.w_state,
  cd.cd_gender
HAVING
  SUM(cs.cs_net_paid) > 10000
ORDER BY total_sales_net DESC
LIMIT 100
