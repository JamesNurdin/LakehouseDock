WITH store_agg AS (
   SELECT
       c.c_customer_id,
       SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
       'store' AS sales_channel
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   WHERE ss.ss_coupon_amt > 100
   GROUP BY c.c_customer_id
),
web_agg AS (
   SELECT
       c.c_customer_id,
       SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
       'web' AS sales_channel
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE ws.ws_coupon_amt > 100
   GROUP BY c.c_customer_id
)
SELECT *
FROM (
   SELECT c_customer_id, total_net_paid, sales_channel FROM store_agg
   UNION ALL
   SELECT c_customer_id, total_net_paid, sales_channel FROM web_agg
) AS combined
ORDER BY total_net_paid DESC,
         sales_channel
LIMIT 100
