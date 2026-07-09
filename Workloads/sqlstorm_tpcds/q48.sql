WITH unified AS (
    SELECT 'store_sales' AS channel,
           d.d_year,
           i.i_category,
           ss.ss_net_profit AS net_profit,
           CAST(0 AS decimal(7,2)) AS net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT 'catalog_sales' AS channel,
           d.d_year,
           i.i_category,
           cs.cs_net_profit,
           CAST(0 AS decimal(7,2))
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT 'web_sales' AS channel,
           d.d_year,
           i.i_category,
           ws.ws_net_profit,
           CAST(0 AS decimal(7,2))
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    UNION ALL
    SELECT 'store_returns' AS channel,
           d.d_year,
           i.i_category,
           CAST(0 AS decimal(7,2)),
           sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT 'catalog_returns' AS channel,
           d.d_year,
           i.i_category,
           CAST(0 AS decimal(7,2)),
           cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT 'web_returns' AS channel,
           d.d_year,
           i.i_category,
           CAST(0 AS decimal(7,2)),
           wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
)
SELECT channel,
       d_year,
       i_category,
       sum(net_profit) AS total_profit,
       sum(net_loss) AS total_loss,
       sum(net_profit) - sum(net_loss) AS net_result
FROM unified
WHERE d_year BETWEEN 1999 AND 2000
GROUP BY channel, d_year, i_category
ORDER BY channel, total_profit DESC
