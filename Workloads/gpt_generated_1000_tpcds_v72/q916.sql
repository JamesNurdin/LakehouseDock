WITH catalog_agg AS (
    SELECT
        w.w_state AS state,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        (SELECT AVG(cs2.cs_net_profit)
         FROM catalog_sales cs2
         JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2000) AS avg_year_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd
          WHERE cd.cd_demo_sk = cs.cs_bill_cdemo_sk
            AND cd.cd_gender = 'M'
      )
    GROUP BY w.w_state
),
web_agg AS (
    SELECT
        w.w_state AS state,
        CASE WHEN SUM(ws.ws_net_profit) > 8000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        (SELECT AVG(ws2.ws_net_profit)
         FROM web_sales ws2
         JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2000) AS avg_year_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd
          WHERE cd.cd_demo_sk = ws.ws_bill_cdemo_sk
            AND cd.cd_gender = 'F'
      )
    GROUP BY w.w_state
)
SELECT state, profit_category, total_net_profit, avg_year_net_profit
FROM catalog_agg
UNION ALL
SELECT state, profit_category, total_net_profit, avg_year_net_profit
FROM web_agg
ORDER BY state, profit_category
LIMIT 100
