WITH store_sales_agg AS (
    SELECT d.d_year,
           cd.cd_gender,
           SUM(ss.ss_net_profit) AS net_profit,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cd.cd_gender
),
catalog_sales_agg AS (
    SELECT d.d_year,
           cd.cd_gender,
           SUM(cs.cs_net_profit) AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cd.cd_gender
),
web_sales_agg AS (
    SELECT d.d_year,
           cd.cd_gender,
           SUM(ws.ws_net_profit) AS net_profit,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cd.cd_gender
)
SELECT combined.d_year,
       combined.cd_gender,
       combined.channel,
       combined.net_profit
FROM (
    SELECT d_year, cd_gender, channel, net_profit FROM store_sales_agg
    UNION ALL
    SELECT d_year, cd_gender, channel, net_profit FROM catalog_sales_agg
    UNION ALL
    SELECT d_year, cd_gender, channel, net_profit FROM web_sales_agg
) AS combined
ORDER BY combined.d_year,
         combined.cd_gender,
         combined.channel
