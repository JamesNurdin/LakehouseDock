SELECT
    d.d_year AS return_year,
    SUM(sr.sr_net_loss) AS total_net_loss,
    'Store' AS source_type
FROM store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
WHERE d.d_weekend = 'Y'
  AND sr.sr_reason_sk = 32
GROUP BY d.d_year

UNION ALL

SELECT
    d.d_year AS return_year,
    SUM(wr.wr_net_loss) AS total_net_loss,
    'Web' AS source_type
FROM web_returns wr
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_weekend = 'Y'
  AND w.w_gmt_offset = -5.00
  AND i.inv_quantity_on_hand > 100
GROUP BY d.d_year
ORDER BY return_year, source_type
LIMIT 100
