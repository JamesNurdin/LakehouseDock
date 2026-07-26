WITH month_losses AS (
 SELECT d.d_year,
        d.d_month_seq,
        SUM(CASE WHEN p.p_channel_tv = 'Y' THEN wr.wr_net_loss ELSE 0 END) AS tv_net_loss,
        SUM(CASE WHEN p.p_channel_email = 'Y' THEN wr.wr_net_loss ELSE 0 END) AS email_net_loss,
        SUM(CASE WHEN p.p_channel_dmail = 'Y' THEN wr.wr_net_loss ELSE 0 END) AS dmail_net_loss,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ws.web_site_sk) AS active_site_cnt
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 LEFT JOIN promotion p ON wr.wr_item_sk = p.p_item_sk
 LEFT JOIN web_site ws ON d.d_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
 WHERE d.d_year BETWEEN 2020 AND 2022
 GROUP BY d.d_year, d.d_month_seq
)
SELECT d_year,
       d_month_seq,
       tv_net_loss,
       email_net_loss,
       dmail_net_loss,
       total_net_loss,
       active_site_cnt,
       CASE WHEN total_net_loss > 10000 THEN 'High' WHEN total_net_loss > 5000 THEN 'Medium' ELSE 'Low' END AS loss_level,
       RANK() OVER (PARTITION BY d_year ORDER BY tv_net_loss DESC) AS tv_rank,
       RANK() OVER (PARTITION BY d_year ORDER BY email_net_loss DESC) AS email_rank,
       RANK() OVER (PARTITION BY d_year ORDER BY dmail_net_loss DESC) AS dmail_rank
FROM month_losses
ORDER BY d_year, d_month_seq
