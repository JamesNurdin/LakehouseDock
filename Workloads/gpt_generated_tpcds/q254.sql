WITH store AS (
    SELECT i.i_category,
           t.t_hour AS hour_of_day,
           ss.ss_net_profit AS net_profit,
           sr.sr_net_loss AS net_loss
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
),
catalog AS (
    SELECT i.i_category,
           t.t_hour AS hour_of_day,
           cs.cs_net_profit AS net_profit,
           cr.cr_net_loss AS net_loss
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
),
web AS (
    SELECT i.i_category,
           t.t_hour AS hour_of_day,
           ws.ws_net_profit AS net_profit,
           wr.wr_net_loss AS net_loss
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT channel,
       i_category,
       hour_of_day,
       SUM(net_profit) AS total_net_profit,
       SUM(COALESCE(net_loss, 0)) AS total_net_loss,
       SUM(net_profit) - SUM(COALESCE(net_loss, 0)) AS net_profit_after_returns
FROM (
    SELECT 'store'   AS channel, i_category, hour_of_day, net_profit, net_loss FROM store
    UNION ALL
    SELECT 'catalog' AS channel, i_category, hour_of_day, net_profit, net_loss FROM catalog
    UNION ALL
    SELECT 'web'     AS channel, i_category, hour_of_day, net_profit, net_loss FROM web
) AS combined
GROUP BY channel, i_category, hour_of_day
ORDER BY channel, total_net_profit DESC, hour_of_day
