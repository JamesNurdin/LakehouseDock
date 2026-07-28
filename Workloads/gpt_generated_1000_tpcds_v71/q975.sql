WITH ws_agg AS (
   SELECT
       ws_item_sk,
       ws_sold_date_sk,
       ws_warehouse_sk,
       ws_ship_mode_sk,
       SUM(ws_net_paid) AS total_net_paid,
       SUM(ws_quantity) AS total_quantity,
       ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn_item
   FROM web_sales
   GROUP BY ws_item_sk, ws_sold_date_sk, ws_warehouse_sk, ws_ship_mode_sk
)
SELECT
    d_sold.d_year,
    i.i_item_id,
    i.i_product_name,
    s_ret.s_store_name,
    w.w_warehouse_name,
    sm.sm_type,
    ws_agg.total_net_paid,
    ws_agg.total_quantity,
    CASE WHEN ws_agg.total_quantity > 20 THEN 'High' ELSE 'Low' END AS quantity_category,
    ws_agg.rn_item AS item_rank
FROM ws_agg
JOIN item i
  ON ws_agg.ws_item_sk = i.i_item_sk
JOIN date_dim d_sold
  ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN warehouse w
  ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
  ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN store s_ret
  ON sr.sr_store_sk = s_ret.s_store_sk
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
  ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN customer c_ret
  ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret
  ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret
  ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN reason r_ret
  ON sr.sr_reason_sk = r_ret.r_reason_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w_inv
  ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE d_sold.d_year = 2001
  AND sm.sm_type = 'AIR'
GROUP BY
    d_sold.d_year,
    i.i_item_id,
    i.i_product_name,
    s_ret.s_store_name,
    w.w_warehouse_name,
    sm.sm_type,
    ws_agg.total_net_paid,
    ws_agg.total_quantity,
    ws_agg.rn_item
HAVING SUM(ws_agg.total_net_paid) > 5000
ORDER BY ws_agg.total_net_paid DESC
LIMIT 100
