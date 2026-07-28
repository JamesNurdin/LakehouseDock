WITH joined_data AS (
  SELECT
    cr.cr_returned_time_sk,
    sr.sr_return_time_sk,
    i.i_class,
    i.i_category,
    sm.sm_carrier,
    w.w_state,
    r.r_reason_desc,
    c.c_preferred_cust_flag,
    hd.hd_buy_potential,
    p.p_discount_active,
    cr.cr_return_quantity            AS cr_qty,
    cr.cr_return_amount              AS cr_amount,
    cr.cr_net_loss                   AS cr_net_loss,
    sr.sr_return_quantity            AS sr_qty,
    sr.sr_return_amt                 AS sr_amount,
    sr.sr_net_loss                   AS sr_net_loss,
    CASE
      WHEN (cr.cr_net_loss + sr.sr_net_loss) > 0 THEN 'Loss'
      ELSE 'Gain'
    END                              AS overall_loss_flag
  FROM catalog_returns cr
  JOIN item i                     ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm               ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w                ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r                   ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer c                 ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN household_demographics hd  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN promotion p                ON p.p_item_sk = i.i_item_sk
  JOIN inventory inv              ON inv.inv_item_sk = i.i_item_sk
                                    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td                ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN store_returns sr           ON sr.sr_item_sk = i.i_item_sk
                                    AND sr.sr_customer_sk = c.c_customer_sk
                                    AND sr.sr_hdemo_sk = hd.hd_demo_sk
                                    AND sr.sr_return_time_sk = td.t_time_sk
  JOIN store s                    ON sr.sr_store_sk = s.s_store_sk
  WHERE i.i_class = 'shirts'
    AND sm.sm_carrier = 'UPS'
    AND hd.hd_income_band_sk = 10
    AND w.w_state = 'CA'
    AND td.t_hour BETWEEN 9 AND 17
)
SELECT
  i_class,
  w_state,
  sm_carrier,
  overall_loss_flag,
  COUNT(*)                                 AS transaction_cnt,
  SUM(cr_qty)                              AS total_catalog_qty,
  SUM(cr_amount)                           AS total_catalog_amount,
  SUM(sr_qty)                              AS total_store_qty,
  SUM(sr_amount)                           AS total_store_amount,
  AVG(cr_net_loss + sr_net_loss)          AS avg_total_net_loss,
  MIN(cr_net_loss + sr_net_loss)          AS min_total_net_loss,
  MAX(cr_net_loss + sr_net_loss)          AS max_total_net_loss
FROM joined_data
GROUP BY ROLLUP (i_class, w_state, sm_carrier, overall_loss_flag)
ORDER BY i_class, w_state, sm_carrier, overall_loss_flag
LIMIT 100
