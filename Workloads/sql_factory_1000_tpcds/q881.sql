WITH daily_loss AS (
    SELECT
        d.d_date,
        d.d_month_seq,
        COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_net_loss,
        COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_loss,
        COALESCE(SUM(cr.cr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss,
        MAX(cr.cr_return_quantity) AS max_return_qty
    FROM date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_month_seq
)
SELECT
    d_date,
    catalog_net_loss,
    web_net_loss,
    total_net_loss,
    max_return_qty,
    CASE WHEN max_return_qty > 5 THEN 'High Return Qty' ELSE 'Normal Return Qty' END AS return_qty_flag,
    RANK() OVER (ORDER BY max_return_qty DESC) AS qty_rank,
    PERCENT_RANK() OVER (ORDER BY total_net_loss DESC) AS loss_percent_rank
FROM daily_loss
WHERE total_net_loss > 0 AND d_month_seq BETWEEN 120 AND 130
ORDER BY qty_rank
LIMIT 25
