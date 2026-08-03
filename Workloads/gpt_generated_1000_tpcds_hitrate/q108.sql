WITH
  agg_cs AS (
    SELECT
      cs_order_number,
      cs_item_sk,
      SUM(cs_net_profit) AS total_cs_net_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY cs_order_number, cs_item_sk
  ),
  ship_air AS (
    SELECT sm_ship_mode_sk, sm_type
    FROM ship_mode
    WHERE sm_type = 'AIR'
  ),
  warehouse_ca AS (
    SELECT w_warehouse_sk, w_warehouse_name, w_state
    FROM warehouse
    WHERE w_state = 'CA'
  ),
  flag_set AS (
    SELECT 1 AS flag UNION ALL SELECT 2 AS flag
  )
SELECT
  d.d_year,
  c.c_customer_id,
  cd.cd_gender,
  sm.sm_type,
  w.w_warehouse_name,
  SUM(agg_cs.total_cs_net_profit)               AS sum_net_profit,
  SUM(cr.cr_net_loss)                           AS sum_catalog_return_loss,
  SUM(sr.sr_net_loss)                           AS sum_store_return_loss,
  SUM(wr.wr_net_loss)                           AS sum_web_return_loss,
  COUNT(DISTINCT agg_cs.cs_order_number)        AS order_cnt,
  AVG(inv.inv_quantity_on_hand)                 AS avg_inventory_qty
FROM agg_cs
JOIN catalog_returns cr
  ON agg_cs.cs_order_number = cr.cr_order_number
 AND agg_cs.cs_item_sk      = cr.cr_item_sk
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN ship_air sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse_ca w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
  ON w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store_sales ss
  ON ss.ss_customer_sk = c.c_customer_sk
 AND ss.ss_sold_date_sk = d.d_date_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
 AND sr.sr_returned_date_sk = d.d_date_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_returns wr
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
CROSS JOIN flag_set f
WHERE cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
  AND inv.inv_quantity_on_hand > 200
  AND d.d_year = 2001
  AND sm.sm_type = 'AIR'
GROUP BY
  d.d_year,
  c.c_customer_id,
  cd.cd_gender,
  sm.sm_type,
  w.w_warehouse_name
ORDER BY sum_net_profit DESC
LIMIT 100
