WITH c_catalog AS (
   SELECT
       i.i_brand,
       sm.sm_type,
       td.t_shift,
       cr.cr_net_loss AS net_loss,
       cr.cr_return_quantity AS return_qty
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE sm.sm_ship_mode_id = 'AAAAAAAACAAAAAAA'
     AND td.t_shift = 'first'
     AND i.i_brand = 'exportiamalg #1'
     AND hd.hd_vehicle_count > 1
),

c_store AS (
   SELECT
       i.i_brand,
       CAST(NULL AS varchar) AS sm_type,
       td.t_shift,
       sr.sr_net_loss AS net_loss,
       sr.sr_return_quantity AS return_qty
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE td.t_hour = 9
     AND i.i_brand = 'importoscholar #2'
     AND hd.hd_dep_count = 2
     AND r.r_reason_desc LIKE '%damaged%'
),

c_web AS (
   SELECT
       i.i_brand,
       CAST(NULL AS varchar) AS sm_type,
       td.t_shift,
       wr.wr_net_loss AS net_loss,
       wr.wr_return_quantity AS return_qty
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE td.t_second = 12
     AND i.i_brand = 'brandnameless #5'
     AND hd.hd_income_band_sk = 3
     AND r.r_reason_desc = 'Customer not satisfied'
),

all_returns AS (
   SELECT i_brand, sm_type, t_shift, net_loss, return_qty FROM c_catalog
   UNION ALL
   SELECT i_brand, sm_type, t_shift, net_loss, return_qty FROM c_store
   UNION ALL
   SELECT i_brand, sm_type, t_shift, net_loss, return_qty FROM c_web
),

agg AS (
   SELECT
       i_brand,
       sm_type,
       t_shift,
       SUM(net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt,
       AVG(return_qty) AS avg_return_qty
   FROM all_returns
   GROUP BY i_brand, sm_type, t_shift
)
SELECT
   i_brand,
   sm_type,
   t_shift,
   total_net_loss,
   return_cnt,
   avg_return_qty,
   SUM(total_net_loss) OVER (PARTITION BY i_brand ORDER BY total_net_loss DESC ROWS UNBOUNDED PRECEDING) AS cumulative_loss_by_brand
FROM agg
ORDER BY cumulative_loss_by_brand DESC
LIMIT 100
