WITH refunded_agg AS (
   SELECT
       d.d_year,
       hd.hd_vehicle_count,
       COUNT(*) AS total_returns,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_net_loss) AS total_net_loss,
       (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2 WHERE wr2.wr_reason_sk = 40) AS avg_return_amt_reason_40
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND hd.hd_vehicle_count >= 2
   GROUP BY d.d_year, hd.hd_vehicle_count
),
returning_agg AS (
   SELECT
       d.d_year,
       hd.hd_vehicle_count,
       COUNT(*) AS total_returns,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_net_loss) AS total_net_loss,
       (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2 WHERE wr2.wr_reason_sk = 40) AS avg_return_amt_reason_40
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND hd.hd_vehicle_count >= 2
   GROUP BY d.d_year, hd.hd_vehicle_count
)
SELECT
   d_year,
   hd_vehicle_count,
   total_returns,
   total_return_amount,
   total_net_loss,
   avg_return_amt_reason_40
FROM refunded_agg
UNION ALL
SELECT
   d_year,
   hd_vehicle_count,
   total_returns,
   total_return_amount,
   total_net_loss,
   avg_return_amt_reason_40
FROM returning_agg
ORDER BY d_year DESC, hd_vehicle_count ASC
LIMIT 100
