WITH daily_loss AS (
    SELECT
        d.d_date,
        d.d_weekend,
        COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_net_loss,
        COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_loss,
        COALESCE(SUM(cr.cr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss
    FROM date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date, d.d_weekend
)
SELECT
    d_date,
    catalog_net_loss,
    web_net_loss,
    total_net_loss,
    CASE WHEN d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS weekend_flag,
    ROW_NUMBER() OVER (ORDER BY catalog_net_loss DESC) AS catalog_rank,
    PERCENT_RANK() OVER (ORDER BY total_net_loss ASC) AS loss_percent_rank_asc
FROM daily_loss
WHERE total_net_loss >= 0
ORDER BY catalog_rank
LIMIT 10
