WITH
  agg_returns AS (
    SELECT
      r.r_reason_sk,
      r.r_reason_desc,
      SUM(cr.cr_net_loss) AS total_net_loss,
      AVG(cr.cr_return_amount) AS avg_return_amount,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_return_ship_cost > 100
      AND cr.cr_store_credit BETWEEN 10 AND 200
      AND cr.cr_refunded_cash > 0
      AND cr.cr_return_quantity > 0
      AND t.t_hour BETWEEN 8 AND 17
      AND t.t_minute < 30
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY r.r_reason_sk, r.r_reason_desc
  ),
  agg_store_credit AS (
    SELECT
      r.r_reason_sk,
      r.r_reason_desc,
      SUM(cr.cr_store_credit) AS total_store_credit,
      CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_return_ship_cost > 150
      AND cr.cr_store_credit > 20
      AND cr.cr_refunded_cash > 50
      AND t.t_hour BETWEEN 9 AND 16
      AND t.t_second % 2 = 0
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY r.r_reason_sk, r.r_reason_desc
  )
SELECT *
FROM (
  SELECT
    ar.r_reason_desc AS reason,
    ar.total_net_loss AS metric_value,
    'NET_LOSS' AS metric_type,
    ar.return_cnt AS cnt
  FROM agg_returns ar
  WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr_no
    WHERE cr_no.cr_reason_sk = ar.r_reason_sk
      AND cr_no.cr_refunded_cash = 0
  )
  UNION ALL
  SELECT
    asc.r_reason_desc AS reason,
    asc.total_store_credit AS metric_value,
    CASE WHEN asc.amount_category = 'HIGH' THEN 'HIGH_CREDIT' ELSE 'LOW_CREDIT' END AS metric_type,
    NULL AS cnt
  FROM agg_store_credit asc
) combined
ORDER BY metric_value DESC
LIMIT 100
