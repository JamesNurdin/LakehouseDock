WITH joined AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        s.s_zip,
        d.d_year,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        t.t_hour
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE s.s_zip IN ('35804', '39303')
      AND d.d_year = 2000
      AND t.t_hour BETWEEN 9 AND 17
      AND sr.sr_return_quantity > 1
),
agg AS (
    SELECT
        d_year,
        s_store_name,
        s_zip,
        SUM(sr_net_loss) AS store_return_loss,
        SUM(wr_net_loss) AS web_return_loss,
        SUM(sr_net_loss + wr_net_loss) AS total_net_loss
    FROM joined
    GROUP BY d_year, s_store_name, s_zip
)
SELECT
    d_year,
    s_store_name,
    s_zip,
    store_return_loss,
    web_return_loss,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
