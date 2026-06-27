WITH hourly_page_returns AS (
    SELECT
        td.t_hour,
        wp.wp_type,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        AVG(wp.wp_char_count) AS avg_page_char_count
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt > 0
    GROUP BY td.t_hour, wp.wp_type
)
SELECT
    hpr.t_hour,
    hpr.wp_type,
    hpr.return_cnt,
    hpr.total_return_amt,
    hpr.total_net_loss,
    hpr.avg_return_qty,
    hpr.avg_page_char_count,
    RANK() OVER (PARTITION BY hpr.t_hour ORDER BY hpr.total_return_amt DESC) AS rank_by_return_amt
FROM hourly_page_returns hpr
ORDER BY hpr.t_hour, rank_by_return_amt
