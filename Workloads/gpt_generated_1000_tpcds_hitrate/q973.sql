WITH
  store_agg AS (
    SELECT
      'store' AS return_category,
      s.s_store_name,
      t.t_shift,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS cnt_returns,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(sr.sr_return_amt) DESC) AS store_rank
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_shift = 'first'
      AND EXISTS (
        SELECT 1 FROM time_dim t2
        WHERE t2.t_hour = t.t_hour
          AND t2.t_minute = t.t_minute
      )
    GROUP BY s.s_store_name, t.t_shift
  ),
  web_agg AS (
    SELECT
      'web' AS return_category,
      CAST(NULL AS varchar) AS s_store_name,
      t.t_shift,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(*) AS cnt_returns,
      ROW_NUMBER() OVER (PARTITION BY t.t_shift ORDER BY SUM(wr.wr_return_amt) DESC) AS shift_rank
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_shift = 'first'
    GROUP BY t.t_shift
  ),
  combined AS (
    SELECT
      return_category,
      s_store_name,
      t_shift,
      total_return_amt,
      cnt_returns,
      store_rank AS rank_num
    FROM store_agg
    UNION ALL
    SELECT
      return_category,
      s_store_name,
      t_shift,
      total_return_amt,
      cnt_returns,
      shift_rank AS rank_num
    FROM web_agg
  )
SELECT
  return_category,
  t_shift,
  SUM(total_return_amt) AS sum_return_amt,
  SUM(cnt_returns) AS sum_cnt_returns,
  MAX(rank_num) AS max_rank,
  (SELECT AVG(sr_return_amt) FROM store_returns) AS avg_store_return_amt
FROM combined
GROUP BY ROLLUP (return_category, t_shift)
ORDER BY
  CASE WHEN return_category IS NULL THEN 1 ELSE 0 END,
  return_category,
  t_shift
LIMIT 100
