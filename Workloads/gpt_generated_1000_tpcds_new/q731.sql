WITH catalog_filtered AS (
   SELECT cr.cr_returned_date_sk,
          cr.cr_return_amount,
          cr.cr_return_quantity,
          cr.cr_net_loss,
          cp.cp_department,
          sm.sm_carrier,
          r.r_reason_desc,
          t.t_sub_shift,
          cr.cr_reason_sk
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   WHERE cr.cr_return_amount > 500
     AND cr.cr_return_quantity BETWEEN 1 AND 10
     AND sm.sm_carrier = 'GREAT EASTERN'
     AND t.t_sub_shift = 'morning'
     AND cp.cp_department = 'Electronics'
),
store_demo AS (
   SELECT sr.sr_returned_date_sk,
          sr.sr_return_quantity,
          sr.sr_net_loss,
          r.r_reason_desc AS store_reason_desc,
          t.t_sub_shift,
          cd.cd_gender,
          sr.sr_reason_sk,
          t.t_time_sk
   FROM store_returns sr
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE sr.sr_return_quantity > 0
     AND t.t_sub_shift = 'evening'
     AND r.r_reason_desc LIKE '%defect%'
),
web_demo AS (
   SELECT wr.wr_returned_date_sk,
          wr.wr_return_quantity,
          wr.wr_net_loss,
          r.r_reason_desc AS web_reason_desc,
          t.t_sub_shift,
          wp.wp_type,
          wr.wr_reason_sk,
          t.t_time_sk
   FROM web_returns wr
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wr.wr_return_quantity > 0
     AND wp.wp_type = 'article'
     AND t.t_sub_shift = 'evening'
),
store_web_full AS (
   SELECT COALESCE(s.t_time_sk, w.t_time_sk) AS time_key,
          s.store_reason_desc AS store_reason,
          w.web_reason_desc AS web_reason,
          s.sr_return_quantity AS store_qty,
          w.wr_return_quantity AS web_qty,
          s.sr_net_loss AS store_loss,
          w.wr_net_loss AS web_loss
   FROM store_demo s
   FULL OUTER JOIN web_demo w
       ON s.t_time_sk = w.t_time_sk
)
SELECT cf.cp_department,
       cf.sm_carrier,
       cf.r_reason_desc AS catalog_reason,
       cf.t_sub_shift AS catalog_shift,
       SUM(cf.cr_return_amount) AS total_catalog_return_amount,
       AVG(cf.cr_return_quantity) AS avg_catalog_return_qty,
       COUNT(DISTINCT cf.cr_returned_date_sk) AS distinct_catalog_return_days,
       SUM(fw.store_qty) AS total_store_return_qty,
       SUM(fw.web_qty) AS total_web_return_qty,
       SUM(fw.store_loss) AS total_store_net_loss,
       SUM(fw.web_loss) AS total_web_net_loss
FROM catalog_filtered cf
LEFT JOIN store_web_full fw
  ON cf.r_reason_desc = fw.store_reason
WHERE cf.cr_reason_sk IN (
        SELECT cr_reason_sk FROM catalog_returns WHERE cr_return_amount > 800
        INTERSECT
        SELECT sr_reason_sk FROM store_returns WHERE sr_return_quantity > 5
      )
GROUP BY cf.cp_department, cf.sm_carrier, cf.r_reason_desc, cf.t_sub_shift
ORDER BY total_catalog_return_amount DESC
LIMIT 100
