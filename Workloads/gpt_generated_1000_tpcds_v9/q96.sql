WITH agg_refunded AS (
   SELECT 
      r.r_reason_desc AS reason,
      CASE WHEN wr.wr_return_amt > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
      SUM(wr.wr_return_amt) AS total_return_amount,
      COUNT(*) AS return_cnt,
      d.d_year AS return_year
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ib.ib_lower_bound >= 80000
     AND d.d_year = 2001
     AND wr.wr_reason_sk IN (SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%fault%')
   GROUP BY r.r_reason_desc,
            CASE WHEN wr.wr_return_amt > 1000 THEN 'High' ELSE 'Low' END,
            d.d_year
   HAVING SUM(wr.wr_return_amt) > 5000
),
agg_returning AS (
   SELECT 
      r.r_reason_desc AS reason,
      CASE WHEN wr.wr_return_amt > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
      SUM(wr.wr_return_amt) AS total_return_amount,
      COUNT(*) AS return_cnt,
      d.d_year AS return_year
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ib.ib_lower_bound < 80000
     AND d.d_year = 2002
     AND wr.wr_reason_sk IN (SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%fault%')
   GROUP BY r.r_reason_desc,
            CASE WHEN wr.wr_return_amt > 1000 THEN 'High' ELSE 'Low' END,
            d.d_year
   HAVING SUM(wr.wr_return_amt) > 3000
),
combined AS (
   SELECT reason, amount_category, total_return_amount, return_cnt, return_year FROM agg_refunded
   UNION ALL
   SELECT reason, amount_category, total_return_amount, return_cnt, return_year FROM agg_returning
)
SELECT 
   reason,
   amount_category,
   total_return_amount,
   return_cnt,
   return_year,
   ROW_NUMBER() OVER (PARTITION BY reason ORDER BY total_return_amount DESC) AS reason_rank
FROM combined
ORDER BY total_return_amount DESC
LIMIT 100
