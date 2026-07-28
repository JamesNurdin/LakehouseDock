WITH base_sales AS (
   SELECT
       cd.cd_demo_sk,
       cd.cd_gender AS gender,
       w.w_warehouse_sk,
       w.w_city AS city,
       ss.ss_net_paid_inc_tax AS store_net_paid,
       ws.ws_net_paid_inc_ship AS web_net_paid,
       ss.ss_ticket_number AS ticket_num,
       ws.ws_order_number AS order_num
   FROM store_sales ss
   JOIN customer_demographics cd
       ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN web_sales ws
       ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN warehouse w
       ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE w.w_gmt_offset = -5.00
     AND ss.ss_net_paid_inc_tax > 1000
     AND ws.ws_sales_price BETWEEN 10 AND 50
),

agg_sales AS (
   SELECT
       gender,
       city,
       SUM(store_net_paid) AS store_total,
       SUM(web_net_paid) AS web_total,
       COUNT(DISTINCT ticket_num) AS store_txn,
       COUNT(DISTINCT order_num) AS web_txn
   FROM base_sales
   GROUP BY gender, city
),

filtered_agg AS (
   SELECT
       gender,
       city,
       store_total,
       web_total,
       (store_total + web_total) AS total_net,
       (store_txn + web_txn) AS total_txn
   FROM agg_sales
   WHERE (store_total + web_total) > 5000
)

SELECT DISTINCT
   gender,
   city,
   total_net,
   total_txn
FROM filtered_agg
WHERE total_txn >= 5

UNION ALL

SELECT
   gender,
   city,
   total_net,
   total_txn
FROM filtered_agg
WHERE gender = 'M' AND total_net > 20000

ORDER BY total_net DESC
LIMIT 100
