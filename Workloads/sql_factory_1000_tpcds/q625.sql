WITH daily_store_returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_date,
        SUM(sr.sr_return_amt) AS daily_return_amt,
        SUM(sr.sr_net_loss) AS daily_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_date
)
SELECT
    s_store_sk,
    s_store_name,
    d_date,
    daily_return_amt,
    daily_net_loss,
    SUM(daily_return_amt) OVER (PARTITION BY s_store_sk ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt,
    AVG(daily_return_amt) OVER (PARTITION BY s_store_sk ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7day,
    RANK() OVER (PARTITION BY s_store_sk ORDER BY daily_return_amt DESC) AS daily_return_rank,
    CASE WHEN daily_return_amt > 1000 THEN 'High' WHEN daily_return_amt > 500 THEN 'Medium' ELSE 'Low' END AS return_amount_category
FROM daily_store_returns
ORDER BY s_store_sk, d_date
