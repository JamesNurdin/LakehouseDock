WITH profit AS (
    SELECT t_hour,
           SUM(net_profit) AS total_profit
    FROM (
        SELECT td.t_hour,
               ss.ss_net_profit AS net_profit
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        UNION ALL
        SELECT td.t_hour,
               cs.cs_net_profit
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        UNION ALL
        SELECT td.t_hour,
               ws.ws_net_profit
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    ) u
    GROUP BY t_hour
),
loss AS (
    SELECT t_hour,
           SUM(net_loss) AS total_loss
    FROM (
        SELECT td.t_hour,
               sr.sr_net_loss AS net_loss
        FROM store_returns sr
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        UNION ALL
        SELECT td.t_hour,
               cr.cr_net_loss
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        UNION ALL
        SELECT td.t_hour,
               wr.wr_net_loss
        FROM web_returns wr
        JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    ) u
    GROUP BY t_hour
),
reason_loss AS (
    SELECT t_hour,
           r_reason_desc,
           SUM(net_loss) AS loss_by_reason
    FROM (
        SELECT td.t_hour,
               r.r_reason_desc,
               sr.sr_net_loss AS net_loss
        FROM store_returns sr
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        UNION ALL
        SELECT td.t_hour,
               r.r_reason_desc,
               cr.cr_net_loss
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        UNION ALL
        SELECT td.t_hour,
               r.r_reason_desc,
               wr.wr_net_loss
        FROM web_returns wr
        JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    ) u
    GROUP BY t_hour, r_reason_desc
),
top_reason AS (
    SELECT t_hour,
           r_reason_desc AS top_reason_desc,
           loss_by_reason AS top_reason_loss,
           ROW_NUMBER() OVER (PARTITION BY t_hour ORDER BY loss_by_reason DESC) AS rn
    FROM reason_loss
)
SELECT profit.t_hour,
       profit.total_profit,
       loss.total_loss,
       profit.total_profit - loss.total_loss AS net_effect,
       tr.top_reason_desc,
       tr.top_reason_loss
FROM profit
JOIN loss ON profit.t_hour = loss.t_hour
LEFT JOIN (
    SELECT t_hour, top_reason_desc, top_reason_loss
    FROM top_reason
    WHERE rn = 1
) tr ON profit.t_hour = tr.t_hour
ORDER BY profit.t_hour
