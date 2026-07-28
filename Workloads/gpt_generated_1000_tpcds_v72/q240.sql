WITH filtered_dates AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM date_dim
    WHERE d_year = 2001
)
SELECT reason_desc,
       year,
       month,
       total_net_loss,
       return_cnt,
       channel
FROM (
    SELECT r.r_reason_desc AS reason_desc,
           fd.d_year AS year,
           fd.d_month_seq AS month,
           SUM(sr.sr_net_loss) AS total_net_loss,
           COUNT(*) AS return_cnt,
           'store' AS channel
    FROM filtered_dates fd
    JOIN store_returns sr ON sr.sr_returned_date_sk = fd.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc, fd.d_year, fd.d_month_seq
    HAVING SUM(sr.sr_net_loss) > 1000

    UNION ALL

    SELECT r.r_reason_desc AS reason_desc,
           fd.d_year AS year,
           fd.d_month_seq AS month,
           SUM(wr.wr_net_loss) AS total_net_loss,
           COUNT(*) AS return_cnt,
           'web' AS channel
    FROM filtered_dates fd
    JOIN web_returns wr ON wr.wr_returned_date_sk = fd.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc, fd.d_year, fd.d_month_seq
    HAVING SUM(wr.wr_net_loss) > 1000
) AS combined_returns
ORDER BY total_net_loss DESC,
         return_cnt DESC
LIMIT 100
