WITH bill_stats AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        'bill' AS source
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_count >= 2
      AND ws.ws_ext_discount_amt > 500
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
ship_stats AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        'ship' AS source
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_college_count >= 3
      AND ws.ws_ext_discount_amt > 500
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT gender,
       marital_status,
       total_net_profit,
       avg_discount,
       source
FROM bill_stats
UNION ALL
SELECT gender,
       marital_status,
       total_net_profit,
       avg_discount,
       source
FROM ship_stats
ORDER BY total_net_profit DESC
