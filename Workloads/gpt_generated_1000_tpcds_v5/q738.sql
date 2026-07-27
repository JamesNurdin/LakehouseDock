WITH high_rev_charge_warehouses AS (
  SELECT DISTINCT cr.cr_warehouse_sk AS w_warehouse_sk
  FROM catalog_returns cr
  WHERE cr.cr_reversed_charge > 200
),
reason_stats AS (
  SELECT
    r.r_reason_sk,
    AVG(cr.cr_return_amount) AS avg_ret_amt
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  GROUP BY r.r_reason_sk
)
SELECT
  w.w_warehouse_name,
  r.r_reason_desc,
  'total_net_loss' AS metric,
  SUM(cr.cr_net_loss) AS metric_value
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN reason_stats rs ON r.r_reason_sk = rs.r_reason_sk
WHERE cr.cr_return_amount > 100
  AND w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM high_rev_charge_warehouses)
GROUP BY w.w_warehouse_name, r.r_reason_desc
UNION ALL
SELECT
  w.w_warehouse_name,
  r.r_reason_desc,
  'return_count' AS metric,
  CAST(COUNT(*) AS double) AS metric_value
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN reason_stats rs ON r.r_reason_sk = rs.r_reason_sk
WHERE cr.cr_return_quantity = 1
  AND EXISTS (
    SELECT 1 FROM catalog_returns cr3
    WHERE cr3.cr_warehouse_sk = w.w_warehouse_sk
      AND cr3.cr_reversed_charge > 300
  )
GROUP BY w.w_warehouse_name, r.r_reason_desc
ORDER BY w_warehouse_name, r_reason_desc, metric
LIMIT 100
