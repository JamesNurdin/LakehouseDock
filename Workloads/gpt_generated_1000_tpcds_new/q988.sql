WITH
  filtered_returns AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_addr_sk IN (1351281, 2873423, 4562636)
      AND sr_hdemo_sk IN (2733, 4636, 527)
      AND sr_return_ship_cost >= 10.00
      AND sr_return_quantity BETWEEN 1 AND 5
      AND sr_return_amt > 0
  ),
  numbers AS (
    SELECT 1 AS multiplier UNION ALL SELECT 2 UNION ALL SELECT 3
  ),
  aggregated AS (
    SELECT
      r.r_reason_desc,
      CASE
        WHEN sr.sr_net_loss < 50 THEN 'Low'
        WHEN sr.sr_net_loss < 200 THEN 'Medium'
        ELSE 'High'
      END AS loss_bucket,
      SUM(sr.sr_return_amt) AS total_return_amt,
      AVG(sr.sr_return_quantity) AS avg_quantity,
      COUNT(DISTINCT sr.sr_ticket_number) AS cnt_tickets,
      MIN(sr.sr_return_ship_cost) AS min_ship_cost,
      MAX(sr.sr_return_ship_cost) AS max_ship_cost
    FROM filtered_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id = 'AAAAAAAAFAAAAAAA'
    GROUP BY
      r.r_reason_desc,
      CASE
        WHEN sr.sr_net_loss < 50 THEN 'Low'
        WHEN sr.sr_net_loss < 200 THEN 'Medium'
        ELSE 'High'
      END
  )
SELECT
  a.r_reason_desc,
  a.loss_bucket,
  a.total_return_amt,
  a.avg_quantity,
  a.cnt_tickets,
  a.min_ship_cost,
  a.max_ship_cost,
  CASE WHEN a.total_return_amt > 1000 THEN 'HighValue' ELSE 'Regular' END AS value_category,
  a.total_return_amt * n.multiplier AS scaled_return_amt
FROM aggregated a
CROSS JOIN numbers n
ORDER BY a.total_return_amt DESC, n.multiplier
LIMIT 100
