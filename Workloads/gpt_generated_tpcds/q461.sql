WITH all_events AS (
    -- Catalog sales net profit per sold time
    SELECT t.t_hour AS hour_of_day,
           cs.cs_net_profit AS net_profit,
           CAST(0 AS decimal(7,2)) AS net_loss
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk

    UNION ALL

    -- Web sales net profit per sold time
    SELECT t.t_hour AS hour_of_day,
           ws.ws_net_profit AS net_profit,
           CAST(0 AS decimal(7,2)) AS net_loss
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk

    UNION ALL

    -- Catalog returns net loss per returned time
    SELECT t.t_hour AS hour_of_day,
           CAST(0 AS decimal(7,2)) AS net_profit,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk

    UNION ALL

    -- Web returns net loss per returned time
    SELECT t.t_hour AS hour_of_day,
           CAST(0 AS decimal(7,2)) AS net_profit,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk

    UNION ALL

    -- Store returns net loss per returned time
    SELECT t.t_hour AS hour_of_day,
           CAST(0 AS decimal(7,2)) AS net_profit,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
)
SELECT hour_of_day,
       SUM(net_profit) AS total_net_profit,
       SUM(net_loss)   AS total_net_loss,
       SUM(net_profit) - SUM(net_loss) AS net_gain
FROM all_events
GROUP BY hour_of_day
ORDER BY hour_of_day
