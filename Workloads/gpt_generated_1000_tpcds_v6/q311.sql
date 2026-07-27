WITH male_sales AS (
    SELECT d.d_year AS sales_year,
           cd.cd_gender AS gender,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 1999
      AND cd.cd_gender = 'M'
    GROUP BY d.d_year, cd.cd_gender
),
female_sales AS (
    SELECT d.d_year AS sales_year,
           cd.cd_gender AS gender,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 1999
      AND cd.cd_gender = 'F'
    GROUP BY d.d_year, cd.cd_gender
)
SELECT sales_year,
       gender,
       total_net_profit
FROM male_sales
UNION ALL
SELECT sales_year,
       gender,
       total_net_profit
FROM female_sales
ORDER BY sales_year DESC, gender
LIMIT 100
