WITH sampled_store AS (
   SELECT *
   FROM store_returns
   TABLESAMPLE BERNOULLI (10)
),
store_only_orders AS (
   SELECT sr_ticket_number
   FROM sampled_store
   EXCEPT
   SELECT cr_order_number
   FROM catalog_returns
),
filtered_catalog AS (
   SELECT *
   FROM catalog_returns
   WHERE cr_returned_date_sk IN (
       SELECT d_date_sk
       FROM date_dim
       WHERE d_year = 2001
   )
),
joined_data AS (
   SELECT
       d_cr.d_year AS year,
       sm.sm_ship_mode_id AS ship_mode,
       SUM(cr.cr_net_loss) AS total_catalog_net_loss,
       SUM(sr.sr_net_loss) AS total_store_net_loss,
       SUM(wr.wr_net_loss) AS total_web_net_loss,
       COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
       COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
       COUNT(DISTINCT wr.wr_order_number) AS web_orders
   FROM sampled_store sr
   JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
   JOIN customer_demographics cd_sr_refunded ON sr.sr_cdemo_sk = cd_sr_refunded.cd_demo_sk
   JOIN household_demographics hd_sr_refunded ON sr.sr_hdemo_sk = hd_sr_refunded.hd_demo_sk
   JOIN filtered_catalog cr ON cr.cr_returned_date_sk = d_sr.d_date_sk
   JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
   JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
   JOIN customer_demographics cd_cr_returning ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
   JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d_sr.d_date_sk
   JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
   JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
   JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
   JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
   JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
   JOIN store_only_orders soo ON soo.sr_ticket_number = sr.sr_ticket_number
   GROUP BY d_cr.d_year, sm.sm_ship_mode_id
),
final_result AS (
   SELECT
       year,
       ship_mode,
       total_catalog_net_loss,
       total_store_net_loss,
       total_web_net_loss,
       catalog_orders,
       store_tickets,
       web_orders,
       LAG(total_catalog_net_loss) OVER (PARTITION BY ship_mode ORDER BY year) AS lag_catalog_net_loss
   FROM joined_data
)
SELECT *
FROM final_result
ORDER BY year DESC, ship_mode
LIMIT 100
