WITH store_sales_agg AS (
    SELECT cd.cd_gender AS gender,
           'store' AS channel,
           SUM(ss.ss_net_profit) AS net_profit,
           0.0 AS net_loss
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
store_returns_agg AS (
    SELECT cd.cd_gender AS gender,
           'store' AS channel,
           0.0 AS net_profit,
           SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
catalog_sales_agg AS (
    SELECT cd.cd_gender AS gender,
           'catalog' AS channel,
           SUM(cs.cs_net_profit) AS net_profit,
           0.0 AS net_loss
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
catalog_returns_agg AS (
    SELECT cd.cd_gender AS gender,
           'catalog' AS channel,
           0.0 AS net_profit,
           SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
web_sales_agg AS (
    SELECT cd.cd_gender AS gender,
           'web' AS channel,
           SUM(ws.ws_net_profit) AS net_profit,
           0.0 AS net_loss
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
web_returns_agg AS (
    SELECT cd.cd_gender AS gender,
           'web' AS channel,
           0.0 AS net_profit,
           SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
combined AS (
    SELECT gender, channel, net_profit, net_loss FROM store_sales_agg
    UNION ALL
    SELECT gender, channel, net_profit, net_loss FROM store_returns_agg
    UNION ALL
    SELECT gender, channel, net_profit, net_loss FROM catalog_sales_agg
    UNION ALL
    SELECT gender, channel, net_profit, net_loss FROM catalog_returns_agg
    UNION ALL
    SELECT gender, channel, net_profit, net_loss FROM web_sales_agg
    UNION ALL
    SELECT gender, channel, net_profit, net_loss FROM web_returns_agg
)
SELECT gender,
       channel,
       SUM(net_profit) AS total_net_profit,
       SUM(net_loss)   AS total_net_loss,
       SUM(net_profit) - SUM(net_loss) AS net_profit_after_returns
FROM combined
GROUP BY gender, channel
ORDER BY gender, channel
