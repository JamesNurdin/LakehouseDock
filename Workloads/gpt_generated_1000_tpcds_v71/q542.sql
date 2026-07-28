WITH store_monthly AS (
        SELECT d.d_year AS year,
               d.d_month_seq AS month,
               SUM(sr.sr_net_loss) AS total_net_loss,
               CASE WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_month_seq
    ),
    web_monthly AS (
        SELECT d.d_year AS year,
               d.d_month_seq AS month,
               SUM(wr.wr_net_loss) AS total_net_loss,
               CASE WHEN SUM(wr.wr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_year, d.d_month_seq
    )
SELECT 'Store' AS channel,
       sm.year,
       sm.month,
       sm.total_net_loss,
       sm.loss_category
FROM store_monthly sm
UNION ALL
SELECT 'Web' AS channel,
       wm.year,
       wm.month,
       wm.total_net_loss,
       wm.loss_category
FROM web_monthly wm
ORDER BY year DESC, month DESC, channel
