WITH catalog_monthly AS (
    SELECT dd.d_year AS year,
           dd.d_month_seq AS month,
           'Catalog' AS channel,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE dd.d_year = 2001
      AND cd.cd_gender = 'M'
      AND w.w_country = 'United States'
    GROUP BY dd.d_year, dd.d_month_seq
),
web_monthly AS (
    SELECT dd.d_year AS year,
           dd.d_month_seq AS month,
           'Web' AS channel,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE dd.d_year = 2001
      AND cd.cd_gender = 'M'
      AND w.w_country = 'United States'
    GROUP BY dd.d_year, dd.d_month_seq
)
SELECT year,
       month,
       channel,
       total_net_profit
FROM catalog_monthly
UNION ALL
SELECT year,
       month,
       channel,
       total_net_profit
FROM web_monthly
ORDER BY year, month, channel
LIMIT 100
