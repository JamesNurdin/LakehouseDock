WITH store_data AS (
   SELECT
       c.c_customer_id,
       'store' AS channel,
       SUM(ss.ss_net_profit) AS total_profit,
       SUM(ss.ss_ext_tax) AS total_tax
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_marital_status = 'M'
     AND cd.cd_dep_count > 2
     AND EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk)
   GROUP BY c.c_customer_id
),
web_data AS (
   SELECT
       c.c_customer_id,
       'web' AS channel,
       SUM(ws.ws_net_profit) AS total_profit,
       SUM(ws.ws_ext_tax) AS total_tax
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_marital_status = 'S'
     AND cd.cd_dep_count > 1
     AND EXISTS (SELECT 1 FROM web_returns wr WHERE wr.wr_refunded_customer_sk = c.c_customer_sk)
   GROUP BY c.c_customer_id
),
combined AS (
   SELECT * FROM store_data
   UNION ALL
   SELECT * FROM web_data
),
avg_profit AS (
   SELECT channel, AVG(total_profit) AS avg_profit
   FROM combined
   GROUP BY channel
)
SELECT
   c.c_customer_id,
   c.channel,
   c.total_profit,
   CASE
       WHEN c.total_profit > 1000 THEN 'High'
       WHEN c.total_profit > 0 THEN 'Medium'
       ELSE 'Low'
   END AS profit_tier,
   CASE
       WHEN c.total_profit > a.avg_profit THEN 'Above Avg'
       ELSE 'Below Avg'
   END AS relative_to_avg,
   RANK() OVER (PARTITION BY c.channel ORDER BY c.total_profit DESC) AS profit_rank
FROM combined c
JOIN avg_profit a ON c.channel = a.channel
ORDER BY c.channel, profit_rank
LIMIT 100
