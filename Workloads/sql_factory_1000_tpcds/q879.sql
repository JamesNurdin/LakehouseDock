WITH daily_loss AS (
    SELECT
        d.d_date,
        d.d_quarter_name,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS day_count
    FROM date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_quarter_name
    HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 1000
)
SELECT
    d_date,
    d_quarter_name,
    catalog_net_loss,
    web_net_loss,
    total_net_loss,
    day_count,
    NTILE(4) OVER (ORDER BY total_net_loss DESC) AS loss_quartile,
    ROW_NUMBER() OVER (PARTITION BY d_quarter_name ORDER BY total_net_loss DESC) AS quarterly_rank
FROM daily_loss
ORDER BY loss_quartile, quarterly_rank
LIMIT 20
