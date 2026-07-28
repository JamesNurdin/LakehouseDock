WITH filtered AS (
   SELECT
       ws.ws_net_profit,
       ws.ws_wholesale_cost,
       ws.ws_quantity,
       ws.ws_sold_time_sk,
       cd.cd_gender AS cd_gender,
       cd.cd_credit_rating AS cd_credit_rating,
       cd.cd_dep_count,
       c.c_birth_month
   FROM tpcds.web_sales ws
   JOIN tpcds.customer c
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_demographics cd
     ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE ws.ws_wholesale_cost > 50.00
     AND ws.ws_quantity BETWEEN 1 AND 5
     AND cd.cd_dep_count <= 2
     AND cd.cd_credit_rating IN ('Good', 'Low Risk')
     AND c.c_birth_month = 5
     AND ws.ws_sold_time_sk BETWEEN 30000 AND 70000
)
SELECT
   cd_gender,
   cd_credit_rating,
   COUNT(*) AS order_cnt,
   SUM(ws_net_profit) AS total_profit,
   AVG(ws_net_profit) AS avg_profit,
   MIN(ws_net_profit) AS min_profit,
   MAX(ws_net_profit) AS max_profit,
   SUM(CASE WHEN ws_net_profit > 1000 THEN 1 ELSE 0 END) AS high_profit_txns
FROM filtered
GROUP BY GROUPING SETS (
   (cd_gender, cd_credit_rating),
   (cd_gender),
   (cd_credit_rating),
   ()
)
ORDER BY total_profit DESC
LIMIT 100
