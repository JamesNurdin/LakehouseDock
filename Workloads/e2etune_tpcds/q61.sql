WITH site_reason_returns AS (
    SELECT
        ws.web_site_id,
        r.r_reason_desc,
        EXTRACT(YEAR FROM d_ret.d_date) AS return_year,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_quantity
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws
        ON d_ret.d_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
    WHERE d_ret.d_year = 2002
      AND d_ret.d_holiday = 'N'
      AND d_ret.d_weekend = 'Y'
    GROUP BY ws.web_site_id, r.r_reason_desc, EXTRACT(YEAR FROM d_ret.d_date)
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM site_reason_returns
ORDER BY total_net_loss DESC
LIMIT 50
