WITH store_agg AS (
  SELECT
    s.s_store_id,
    s.s_state,
    td.t_hour,
    hd.hd_buy_potential,
    SUM(ss.ss_net_paid)                                 AS sum_store_net_paid,
    SUM(cs.cs_net_paid)                                 AS sum_catalog_net_paid,
    SUM(cs.cs_net_profit)                               AS sum_catalog_net_profit,
    SUM(cr.cr_net_loss)                                 AS sum_return_net_loss,
    SUM(wr.wr_net_loss)                                 AS sum_web_return_net_loss
  FROM store_sales ss
  JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = td.t_time_sk
   AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
   AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE td.t_hour BETWEEN 8 AND 18
    AND s.s_state = 'CA'
    AND hd.hd_income_band_sk > 2
  GROUP BY s.s_store_id, s.s_state, td.t_hour, hd.hd_buy_potential
),
state_summary AS (
  SELECT
    s_state,
    AVG((sum_store_net_paid + sum_catalog_net_paid + sum_catalog_net_profit) - (sum_return_net_loss + sum_web_return_net_loss)) AS avg_net_contribution,
    SUM(sum_store_net_paid) AS total_store_net_paid
  FROM (
    SELECT
      s_state,
      sum_store_net_paid,
      sum_catalog_net_paid,
      sum_catalog_net_profit,
      sum_return_net_loss,
      sum_web_return_net_loss
    FROM store_agg
  ) sub
  GROUP BY s_state
  HAVING AVG((sum_store_net_paid + sum_catalog_net_paid + sum_catalog_net_profit) - (sum_return_net_loss + sum_web_return_net_loss)) > 10000
)
SELECT
  s_state,
  avg_net_contribution,
  total_store_net_paid
FROM state_summary
ORDER BY avg_net_contribution DESC
LIMIT 100
