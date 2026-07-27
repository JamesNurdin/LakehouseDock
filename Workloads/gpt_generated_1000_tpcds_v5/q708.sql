/*
Goal: Compare monthly net profit between catalog sales and web sales for large-sized items in the year 2001.
*/
WITH catalog_monthly AS (
    SELECT d.d_month_seq AS month_seq,
           SUM(cs.cs_net_profit) AS net_profit,
           'Catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_size = 'large'
    GROUP BY d.d_month_seq
),
web_monthly AS (
    SELECT d.d_month_seq AS month_seq,
           SUM(ws.ws_net_profit) AS net_profit,
           'Web' AS channel
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_size = 'large'
    GROUP BY d.d_month_seq
)
SELECT month_seq,
       net_profit,
       channel
FROM catalog_monthly
UNION ALL
SELECT month_seq,
       net_profit,
       channel
FROM web_monthly
ORDER BY month_seq,
         channel
