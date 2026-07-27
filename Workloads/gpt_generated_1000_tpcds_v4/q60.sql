WITH returns_filtered AS (
   SELECT
     cr.cr_warehouse_sk,
     cr.cr_reason_sk,
     cr.cr_returned_date_sk,
     cr.cr_return_amount,
     cr.cr_net_loss,
     cr.cr_return_quantity,
     r.r_reason_desc,
     w.w_warehouse_name,
     w.w_city,
     w.w_state,
     w.w_warehouse_sq_ft
   FROM catalog_returns cr
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE regexp_like(r.r_reason_desc, '(?i)damaged|defective')
     AND w.w_warehouse_name LIKE 'WH%'
),
aggregated AS (
   SELECT
     rf.w_warehouse_name,
     CONCAT(rf.w_city, ', ', rf.w_state) AS location,
     SUBSTR(rf.w_warehouse_name, 1, 3) AS warehouse_prefix,
     REGEXP_EXTRACT(rf.r_reason_desc, '(?i)(damaged|defective)') AS matched_reason,
     COUNT(DISTINCT rf.cr_return_quantity) AS distinct_return_qty,
     SUM(rf.cr_return_amount) AS total_return_amount,
     SUM(rf.cr_net_loss) AS total_net_loss,
     AVG(rf.cr_return_quantity) AS avg_return_qty,
     rf.r_reason_desc
   FROM returns_filtered rf
   GROUP BY
     rf.w_warehouse_name,
     rf.w_city,
     rf.w_state,
     rf.r_reason_desc
)
SELECT
  w_warehouse_name,
  location,
  warehouse_prefix,
  matched_reason,
  distinct_return_qty,
  total_return_amount,
  total_net_loss,
  avg_return_qty
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
