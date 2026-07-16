WITH sr_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(sr.sr_net_loss) AS store_net_loss,
         AVG(sr.sr_return_amt) AS store_avg_return_amt,
         COUNT(*) AS store_return_cnt
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year IN (2001, 2002)
  GROUP BY d.d_year, d.d_month_seq
),
wr_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(wr.wr_net_loss) AS web_net_loss,
         AVG(wr.wr_return_amt) AS web_avg_return_amt,
         COUNT(*) AS web_return_cnt
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year IN (2001, 2002)
  GROUP BY d.d_year, d.d_month_seq
),
cc_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         COUNT(DISTINCT cc.cc_call_center_id) AS call_centers_opened
  FROM call_center cc
  JOIN date_dim d
    ON cc.cc_open_date_sk = d.d_date_sk
  WHERE d.d_year IN (2001, 2002)
  GROUP BY d.d_year, d.d_month_seq
)
SELECT COALESCE(sr.d_year, wr.d_year, cc.d_year) AS year,
       COALESCE(sr.d_month_seq, wr.d_month_seq, cc.d_month_seq) AS month_seq,
       COALESCE(sr.store_net_loss, 0) AS store_net_loss,
       COALESCE(wr.web_net_loss, 0) AS web_net_loss,
       COALESCE(cc.call_centers_opened, 0) AS call_centers_opened,
       COALESCE(sr.store_avg_return_amt, 0) AS store_avg_return_amt,
       COALESCE(wr.web_avg_return_amt, 0) AS web_avg_return_amt,
       COALESCE(sr.store_return_cnt, 0) AS store_return_cnt,
       COALESCE(wr.web_return_cnt, 0) AS web_return_cnt
FROM sr_agg sr
FULL OUTER JOIN wr_agg wr
  ON sr.d_year = wr.d_year AND sr.d_month_seq = wr.d_month_seq
FULL OUTER JOIN cc_agg cc
  ON COALESCE(sr.d_year, wr.d_year) = cc.d_year
  AND COALESCE(sr.d_month_seq, wr.d_month_seq) = cc.d_month_seq
ORDER BY year, month_seq
