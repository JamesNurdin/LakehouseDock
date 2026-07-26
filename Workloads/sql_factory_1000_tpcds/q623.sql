WITH store_yearly AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_market_desc,
        d.d_fy_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN s.s_closed_date_sk IS NULL THEN 'Open' ELSE 'Closed' END AS store_status
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_market_desc, d.d_fy_year, s.s_closed_date_sk
)
SELECT
    s_store_sk,
    s_store_name,
    s_market_desc,
    d_fy_year,
    total_return_amt,
    total_net_loss,
    store_status,
    RANK() OVER (PARTITION BY d_fy_year ORDER BY total_return_amt DESC) AS store_return_rank,
    DENSE_RANK() OVER (PARTITION BY d_fy_year ORDER BY total_net_loss DESC) AS market_net_loss_rank
FROM store_yearly
ORDER BY d_fy_year, store_return_rank
