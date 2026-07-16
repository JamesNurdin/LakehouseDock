WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_credit_rating,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        approx_percentile(wr.wr_return_amt, 0.5) AS median_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer cust ON wr.wr_returning_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wr.wr_return_quantity > 0
      AND cd.cd_gender IN ('M', 'F')
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender, cd.cd_credit_rating
    HAVING COUNT(*) > 10
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.cd_gender,
    a.cd_credit_rating,
    a.return_cnt,
    a.total_net_loss,
    a.avg_return_amount,
    a.median_return_amount,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS net_loss_rank_by_year
FROM agg a
ORDER BY a.d_year, a.total_net_loss DESC
LIMIT 200
