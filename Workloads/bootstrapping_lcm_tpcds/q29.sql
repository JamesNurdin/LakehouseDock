SELECT
  d_ret.d_date_id AS return_date_id,
  d_ret.d_year,
  d_ret.d_month_seq,
  s.s_store_id,
  s.s_store_name,
  r_sr.r_reason_desc AS store_return_reason,
  COUNT(sr.sr_ticket_number) AS store_return_cnt,
  SUM(sr.sr_return_amt) AS store_return_total,
  SUM(sr.sr_net_loss) AS store_net_loss,
  d_closed.d_current_year AS store_closed_year,
  COALESCE(wr_agg.web_return_cnt, 0) AS web_return_cnt,
  COALESCE(wr_agg.web_return_total, 0) AS web_return_total,
  COALESCE(wr_agg.web_net_loss, 0) AS web_net_loss,
  (SUM(sr.sr_return_amt) - COALESCE(wr_agg.web_return_total, 0)) AS diff_return_amt,
  CASE
    WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High'
    ELSE 'Low'
  END AS return_volume_category
FROM store_returns sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN (
    SELECT
      wr.wr_returned_date_sk AS date_sk,
      r_wr.r_reason_sk AS reason_sk,
      COUNT(*) AS web_return_cnt,
      SUM(wr.wr_return_amt) AS web_return_total,
      SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    GROUP BY wr.wr_returned_date_sk, r_wr.r_reason_sk
) wr_agg
  ON wr_agg.date_sk = d_ret.d_date_sk
 AND wr_agg.reason_sk = r_sr.r_reason_sk
WHERE d_ret.d_year = 2022
GROUP BY
  d_ret.d_date_id,
  d_ret.d_year,
  d_ret.d_month_seq,
  s.s_store_id,
  s.s_store_name,
  r_sr.r_reason_desc,
  d_closed.d_current_year,
  wr_agg.web_return_cnt,
  wr_agg.web_return_total,
  wr_agg.web_net_loss
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY diff_return_amt DESC
LIMIT 100
