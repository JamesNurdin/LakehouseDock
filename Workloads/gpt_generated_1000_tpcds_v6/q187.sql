WITH daily_reason_metrics AS (
   SELECT
      d.d_date,
      d.d_year,
      d.d_month_seq,
      r.r_reason_desc,
      SUM(wr.wr_return_amt) AS total_return_amt,
      SUM(wr.wr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      AVG(wr.wr_return_ship_cost) AS avg_ship_cost
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE d.d_year BETWEEN 1905 AND 1910
     AND d.d_dow IN (0, 1, 2, 3, 4, 5)
     AND d.d_fy_year = 1909
     AND r.r_reason_desc LIKE '%did not like%'
     AND wr.wr_return_amt > 20
     AND wr.wr_return_quantity >= 1
   GROUP BY d.d_date, d.d_year, d.d_month_seq, r.r_reason_desc
)
SELECT
   drm.d_date,
   drm.d_year,
   drm.d_month_seq,
   drm.r_reason_desc,
   drm.total_return_amt,
   drm.total_net_loss,
   drm.return_cnt,
   drm.avg_ship_cost,
   RANK() OVER (PARTITION BY drm.d_year ORDER BY drm.total_net_loss DESC) AS net_loss_rank_year,
   ROW_NUMBER() OVER (ORDER BY drm.total_return_amt DESC) AS overall_return_amt_rownum
FROM daily_reason_metrics drm
WHERE drm.return_cnt >= 5
  AND drm.avg_ship_cost < 800
ORDER BY drm.total_net_loss DESC, drm.d_date
LIMIT 100
