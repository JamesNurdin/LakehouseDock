WITH cr_agg AS (
  SELECT
    cr_reason_sk,
    cr_ship_mode_sk,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_ship_cost) AS avg_ship_cost,
    COUNT(*) AS return_cnt
  FROM tpcds.catalog_returns
  WHERE cr_return_quantity > 0
    AND cr_return_ship_cost > 50
    AND cr_return_amount IS NOT NULL
  GROUP BY cr_reason_sk, cr_ship_mode_sk
)
SELECT
  r.r_reason_id,
  r.r_reason_desc,
  AVG(cr_agg.total_return_amount) AS avg_total_return_amount,
  SUM(cr_agg.return_cnt) AS total_returns,
  MAX(
    (SELECT MAX(cr_return_amount)
     FROM tpcds.catalog_returns cr2
     WHERE cr2.cr_reason_sk = cr_agg.cr_reason_sk)
  ) AS max_return_amount_for_reason
FROM cr_agg
JOIN tpcds.reason r
  ON cr_agg.cr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%service%'
  AND cr_agg.avg_ship_cost < 200
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr3
        WHERE cr3.cr_reason_sk = cr_agg.cr_reason_sk
          AND cr3.cr_return_ship_cost > 500
      )
GROUP BY r.r_reason_id, r.r_reason_desc
HAVING AVG(cr_agg.total_return_amount) > 1000
ORDER BY avg_total_return_amount DESC
LIMIT 50
