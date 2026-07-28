/* goal: Compare high‑value return reasons for the current month with high‑cost promotions that started in the current month, while excluding returns that have a promotion starting on the same return date. */
WITH
  returns_agg AS (
    SELECT
      r.r_reason_desc AS reason,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS amount_bucket,
      'Return' AS src
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_current_month = 'Y'
      AND NOT EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_start_date_sk = d.d_date_sk
      )
    GROUP BY r.r_reason_desc
  ),
  promo_agg AS (
    SELECT
      p.p_promo_name AS reason,
      SUM(p.p_cost) AS total_return_amt,
      COUNT(*) AS return_cnt,
      CASE
        WHEN SUM(p.p_cost) > (SELECT MAX(p_cost) FROM promotion) THEN 'Highest'
        ELSE 'Standard'
      END AS amount_bucket,
      'Promotion' AS src
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_current_month = 'Y'
    GROUP BY p.p_promo_name
  )
SELECT
  reason,
  total_return_amt,
  return_cnt,
  amount_bucket,
  src,
  (SELECT AVG(wr_return_amt) FROM web_returns) AS avg_overall_return
FROM (
  SELECT reason, total_return_amt, return_cnt, amount_bucket, src FROM returns_agg
  UNION ALL
  SELECT reason, total_return_amt, return_cnt, amount_bucket, src FROM promo_agg
) combined
ORDER BY amount_bucket DESC, total_return_amt DESC
