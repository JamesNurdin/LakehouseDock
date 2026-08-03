SELECT
  store_id,
  store_name,
  metric,
  total_return,
  loss_flag
FROM (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    metric,
    SUM(sr.sr_return_amt_inc_tax) AS total_return,
    CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_flag
  FROM store s
  JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
  CROSS JOIN UNNEST(ARRAY[s.s_number_employees, s.s_floor_space]) AS t(metric)
  WHERE s.s_state = 'CA'
    AND sr.sr_return_amt_inc_tax > 100
    AND EXISTS (
      SELECT 1 FROM store_returns sr2
      WHERE sr2.sr_store_sk = s.s_store_sk
        AND sr2.sr_fee > 30
    )
  GROUP BY s.s_store_id, s.s_store_name, metric

  UNION

  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    metric,
    SUM(sr.sr_return_amt_inc_tax) AS total_return,
    CASE WHEN SUM(sr.sr_net_loss) > 500 THEN 'MEDIUM' ELSE 'LOW' END AS loss_flag
  FROM store s
  JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
  CROSS JOIN UNNEST(ARRAY[s.s_number_employees, s.s_floor_space]) AS t(metric)
  WHERE s.s_closed_date_sk IS NOT NULL
    AND sr.sr_return_amt_inc_tax < 50
    AND EXISTS (
      SELECT 1 FROM store_returns sr2
      WHERE sr2.sr_store_sk = s.s_store_sk
        AND sr2.sr_fee > 30
    )
  GROUP BY s.s_store_id, s.s_store_name, metric
) AS combined
ORDER BY store_id, metric
