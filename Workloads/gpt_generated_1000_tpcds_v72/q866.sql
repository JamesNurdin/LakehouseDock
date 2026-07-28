WITH store_agg AS (
   SELECT
       'store' AS src,
       ss.ss_ticket_number AS id,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(DISTINCT c1.c_customer_sk) AS unique_customers,
       CASE WHEN SUM(sr.sr_return_amt) > 0 THEN 'Returned' ELSE 'NoReturn' END AS flag
   FROM store_sales ss
   JOIN customer c1 ON ss.ss_customer_sk = c1.c_customer_sk
   JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
   JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
   WHERE EXISTS (
       SELECT 1 FROM catalog_sales cs
       WHERE cs.cs_bill_customer_sk = sr.sr_customer_sk
   )
   GROUP BY ss.ss_ticket_number
),
cat_agg AS (
   SELECT
       'catalog' AS src,
       cs.cs_order_number AS id,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(DISTINCT c_bill.c_customer_sk) AS unique_customers,
       CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'BulkOrder' ELSE 'RegularOrder' END AS flag
   FROM catalog_sales cs
   JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN warehouse w_cat ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
   GROUP BY cs.cs_order_number
),
web_agg AS (
   SELECT
       'web' AS src,
       ws.ws_order_number AS id,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(DISTINCT c_bill_ws.c_customer_sk) AS unique_customers,
       CASE WHEN SUM(ws.ws_coupon_amt) > 5000 THEN 'HighCouponTotal' ELSE 'LowCouponTotal' END AS flag
   FROM web_sales ws
   JOIN customer c_bill_ws ON ws.ws_bill_customer_sk = c_bill_ws.c_customer_sk
   JOIN customer c_ship_ws ON ws.ws_ship_customer_sk = c_ship_ws.c_customer_sk
   JOIN household_demographics hd_bill_ws ON ws.ws_bill_hdemo_sk = hd_bill_ws.hd_demo_sk
   JOIN household_demographics hd_ship_ws ON ws.ws_ship_hdemo_sk = hd_ship_ws.hd_demo_sk
   JOIN warehouse w_web ON ws.ws_warehouse_sk = w_web.w_warehouse_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   GROUP BY ws.ws_order_number
)
SELECT src,
       id,
       total_profit,
       unique_customers,
       flag
FROM (
   SELECT src, id, total_profit, unique_customers, flag FROM store_agg
   UNION ALL
   SELECT src, id, total_profit, unique_customers, flag FROM cat_agg
   UNION ALL
   SELECT src, id, total_profit, unique_customers, flag FROM web_agg
) combined
ORDER BY total_profit DESC
LIMIT 100
