WITH base AS (
   SELECT
       cc.cc_call_center_id,
       cc.cc_state,
       ib.ib_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       i.i_item_id,
       i.i_class,
       i.i_wholesale_cost,
       cr.cr_return_amount,
       cr.cr_net_loss AS cr_net_loss,
       sr.sr_return_amt,
       sr.sr_net_loss AS sr_net_loss
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
   JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
   JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
   JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
   JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
   JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
   WHERE cc.cc_state = 'CA'
     AND i.i_class = 'hockey'
     AND i.i_wholesale_cost > 5.00
     AND ib.ib_lower_bound >= 20000
     AND cr.cr_return_amount > 100.00
     AND sr.sr_return_amt > 200.00
     AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
),
agg AS (
   SELECT
       cc_call_center_id,
       ib_income_band_sk,
       i_class,
       SUM(cr_net_loss) AS total_cr_loss,
       SUM(sr_net_loss) AS total_sr_loss,
       SUM(cr_net_loss) + SUM(sr_net_loss) AS total_loss,
       COUNT(*) AS return_cnt
   FROM base
   GROUP BY cc_call_center_id, ib_income_band_sk, i_class
   HAVING SUM(cr_net_loss) + SUM(sr_net_loss) > 1000
)
SELECT
    cc_call_center_id,
    ib_income_band_sk,
    i_class,
    total_cr_loss,
    total_sr_loss,
    total_loss,
    return_cnt,
    AVG(total_loss) OVER (PARTITION BY cc_call_center_id) AS avg_loss_per_center,
    ROW_NUMBER() OVER (ORDER BY total_loss DESC) AS loss_rank
FROM agg
ORDER BY avg_loss_per_center DESC, total_loss DESC
LIMIT 100
