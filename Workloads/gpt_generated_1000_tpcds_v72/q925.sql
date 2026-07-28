WITH per_item AS (
   SELECT
       i.i_item_id,
       d.d_year,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(sr.sr_net_loss) AS total_store_return_loss,
       SUM(cr.cr_net_loss) AS total_catalog_return_loss,
       SUM(wr.wr_net_loss) AS total_web_return_loss,
       COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_centers
   FROM date_dim d
   JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_item_sk = ss.ss_item_sk
   JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
       AND cr.cr_item_sk = i.i_item_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_item_sk = i.i_item_sk
   JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
   WHERE d.d_year = 2001
     AND i.i_wholesale_cost > 10
     AND hd.hd_vehicle_count >= 1
   GROUP BY i.i_item_id, d.d_year
),
avg_loss AS (
   SELECT AVG(loss_ratio) AS avg_loss_ratio
   FROM (
       SELECT (total_store_return_loss + total_catalog_return_loss + total_web_return_loss) / NULLIF(total_sales, 0) AS loss_ratio
       FROM per_item
   )
)
SELECT
    pi.i_item_id,
    pi.d_year,
    pi.total_sales,
    pi.total_loss,
    pi.loss_ratio,
    pi.distinct_call_centers
FROM (
    SELECT
        i_item_id,
        d_year,
        total_sales,
        (total_store_return_loss + total_catalog_return_loss + total_web_return_loss) AS total_loss,
        (total_store_return_loss + total_catalog_return_loss + total_web_return_loss) / NULLIF(total_sales, 0) AS loss_ratio,
        distinct_call_centers
    FROM per_item
) pi
CROSS JOIN avg_loss al
WHERE pi.loss_ratio > al.avg_loss_ratio
ORDER BY pi.loss_ratio DESC
LIMIT 100
