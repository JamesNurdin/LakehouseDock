WITH inventory_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    s.s_store_id,
    cc.cc_name,
    t.t_hour,
    SUM(sr.sr_net_loss)               AS total_store_return_loss,
    SUM(cr.cr_net_loss)               AS total_catalog_return_loss,
    SUM(ss.ss_net_profit)             AS total_sales_profit,
    CASE
        WHEN SUM(sr.sr_net_loss) > 0 THEN 'StoreLoss'
        WHEN SUM(cr.cr_net_loss) > 0 THEN 'CatalogLoss'
        ELSE 'Profit'
    END                               AS loss_category,
    ia.total_qty                      AS warehouse_inventory_qty
FROM store_sales ss
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN catalog_returns cr
  ON cr.cr_returned_time_sk = t.t_time_sk
 AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg ia
  ON ia.inv_warehouse_sk = w.w_warehouse_sk
WHERE s.s_number_employees > 200
  AND s.s_state = 'CA'
  AND t.t_hour BETWEEN 9 AND 17
  AND hd.hd_vehicle_count >= 1
  AND cr.cr_return_amount > 100
GROUP BY
    s.s_store_id,
    cc.cc_name,
    t.t_hour,
    ia.total_qty
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_sales_profit DESC
LIMIT 100
