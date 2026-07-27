WITH sales_year AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year IN (2000, 2001)
)
SELECT sales_channel,
       year,
       total_profit
FROM (
    SELECT
        'Catalog' AS sales_channel,
        dy.d_year AS year,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN sales_year dy ON cs.cs_sold_date_sk = dy.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
    GROUP BY dy.d_year
    HAVING SUM(cs.cs_net_profit) > 10000

    UNION ALL

    SELECT
        'Web' AS sales_channel,
        dy.d_year AS year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN sales_year dy ON ws.ws_sold_date_sk = dy.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY dy.d_year
    HAVING SUM(ws.ws_net_profit) > 10000
) AS combined
ORDER BY total_profit DESC
LIMIT 100
