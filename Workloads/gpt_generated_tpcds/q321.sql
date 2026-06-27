WITH sales_and_returns AS (
    SELECT t.t_hour AS hour,
           'store_sales' AS channel,
           ss.ss_net_profit AS net_profit,
           CAST(0 AS decimal(7,2)) AS net_loss
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk

    UNION ALL

    SELECT t.t_hour AS hour,
           'store_returns' AS channel,
           CAST(0 AS decimal(7,2)) AS net_profit,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk

    UNION ALL

    SELECT t.t_hour AS hour,
           'catalog_sales' AS channel,
           cs.cs_net_profit AS net_profit,
           CAST(0 AS decimal(7,2)) AS net_loss
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk

    UNION ALL

    SELECT t.t_hour AS hour,
           'catalog_returns' AS channel,
           CAST(0 AS decimal(7,2)) AS net_profit,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk

    UNION ALL

    SELECT t.t_hour AS hour,
           'web_sales' AS channel,
           ws.ws_net_profit AS net_profit,
           CAST(0 AS decimal(7,2)) AS net_loss
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk

    UNION ALL

    SELECT t.t_hour AS hour,
           'web_returns' AS channel,
           CAST(0 AS decimal(7,2)) AS net_profit,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
)
SELECT hour,
       channel,
       sum(net_profit) AS total_net_profit,
       sum(net_loss) AS total_net_loss,
       sum(net_profit) - sum(net_loss) AS net_contribution
FROM sales_and_returns
WHERE hour BETWEEN 8 AND 20
GROUP BY hour, channel
ORDER BY hour, channel
