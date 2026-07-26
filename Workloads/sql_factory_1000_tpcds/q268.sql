WITH daily_loss AS (
    SELECT
        d.d_date,
        d.d_holiday,
        COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_net_loss,
        COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_loss,
        COALESCE(SUM(cr.cr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss
    FROM date_dim d
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_holiday
)
SELECT
    d_date,
    catalog_net_loss,
    web_net_loss,
    total_net_loss,
    CASE WHEN d_holiday = 'Y' THEN 'Holiday' ELSE 'Non-Holiday' END AS holiday_flag,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
    PERCENT_RANK() OVER (ORDER BY total_net_loss DESC) AS loss_percent_rank
FROM daily_loss
WHERE total_net_loss > 0
ORDER BY loss_rank
LIMIT 20
