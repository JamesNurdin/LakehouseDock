SELECT
    s.s_store_name,
    i.i_class,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) DESC) AS profit_rank
FROM
    store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
WHERE
    i.i_manager_id = 26
    AND td.t_hour BETWEEN 9 AND 17
    AND s.s_state = 'CA'
GROUP BY
    s.s_store_name,
    i.i_class
HAVING
    SUM(ss.ss_net_profit) > 1000
ORDER BY
    net_profit_after_returns DESC
LIMIT 20
