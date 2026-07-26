SELECT
    d_month.d_year,
    d_month.d_month_seq,
    ws.web_site_id,
    ws.web_manager,
    SUM(wr.wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss'
        WHEN SUM(wr.wr_net_loss) < 0 THEN 'Gain'
        ELSE 'Neutral'
    END AS loss_category,
    ROUND(100.0 * SUM(wr.wr_net_loss) / SUM(SUM(wr.wr_net_loss)) OVER (PARTITION BY d_month.d_year, d_month.d_month_seq), 2) AS pct_of_monthly_loss,
    DENSE_RANK() OVER (PARTITION BY d_month.d_year, d_month.d_month_seq ORDER BY SUM(wr.wr_net_loss) DESC) AS loss_rank,
    AVG(i.i_current_price) AS avg_item_price
FROM web_returns wr
JOIN date_dim d_month
    ON wr.wr_returned_date_sk = d_month.d_date_sk
JOIN web_site ws
    ON d_month.d_date_sk >= ws.web_open_date_sk
   AND (ws.web_close_date_sk IS NULL OR d_month.d_date_sk <= ws.web_close_date_sk)
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
WHERE d_month.d_year >= 2000
GROUP BY d_month.d_year, d_month.d_month_seq, ws.web_site_id, ws.web_manager
HAVING SUM(wr.wr_net_loss) IS NOT NULL
ORDER BY d_month.d_year, d_month.d_month_seq, loss_rank
LIMIT 100
