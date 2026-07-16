WITH cr_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_type AS ship_mode,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_return_date
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
  WHERE cr.cr_reason_sk IN (17, 16, 59, 9, 65)
    AND cr.cr_returned_time_sk IN (49726, 44830, 34647)
    AND d.d_year BETWEEN 2001 AND 2003
  GROUP BY d.d_year, d.d_month_seq, sm.sm_type
),
wr_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'WEB' AS ship_mode,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_return_date
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
  WHERE wr.wr_reason_sk IN (17, 16, 59, 9, 65)
    AND wr.wr_returned_time_sk IN (49726, 44830, 34647)
    AND d.d_year BETWEEN 2001 AND 2003
  GROUP BY d.d_year, d.d_month_seq
)
SELECT
  year,
  month_seq,
  ship_mode,
  total_net_loss,
  total_return_amount,
  avg_return_qty,
  avg_inventory_on_return_date,
  RANK() OVER (PARTITION BY year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
  SELECT d_year AS year, d_month_seq AS month_seq, ship_mode,
         total_net_loss, total_return_amount, avg_return_qty,
         avg_inventory_on_return_date
  FROM cr_agg
  UNION ALL
  SELECT d_year AS year, d_month_seq AS month_seq, ship_mode,
         total_net_loss, total_return_amount, avg_return_qty,
         avg_inventory_on_return_date
  FROM wr_agg
) t
WHERE total_net_loss > 1000
ORDER BY year, month_seq, net_loss_rank
LIMIT 100
