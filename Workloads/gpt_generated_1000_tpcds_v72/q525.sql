WITH avg_price_cte AS (
   SELECT AVG(cs_sales_price) AS avg_price
   FROM catalog_sales
),
agg AS (
   SELECT
       c.c_customer_id,
       ca.ca_city,
       s.s_store_name,
       SUM(cs.cs_net_paid) AS total_catalog_sales,
       SUM(ss.ss_net_paid) AS total_store_sales,
       SUM(ws.ws_net_paid) AS total_web_sales,
       COUNT(DISTINCT ws.ws_order_number) AS web_orders,
       CASE WHEN AVG(cs.cs_sales_price) > (SELECT avg_price FROM avg_price_cte) THEN 'Above Avg' ELSE 'Below Avg' END AS price_category,
       CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS web_spend_category,
       MAX(r.r_reason_desc) AS last_return_reason
   FROM
       customer c
   JOIN customer_address ca
       ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN store_sales ss
       ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN store s
       ON ss.ss_store_sk = s.s_store_sk
   JOIN catalog_sales cs
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN web_sales ws
       ON ws.ws_bill_customer_sk = c.c_customer_sk
   LEFT JOIN web_returns wr
       ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN reason r
       ON wr.wr_reason_sk = r.r_reason_sk
   WHERE
       cs.cs_sales_price > 25.00
       AND ca.ca_city = 'Main'
       AND cc.cc_state = 'CA'
       AND s.s_state = 'CA'
       AND NOT EXISTS (
           SELECT 1 FROM web_returns wr_ex
           WHERE wr_ex.wr_refunded_customer_sk = c.c_customer_sk
       )
   GROUP BY
       c.c_customer_id,
       ca.ca_city,
       s.s_store_name
)
SELECT
   a.c_customer_id,
   a.ca_city,
   a.s_store_name,
   a.total_catalog_sales,
   a.total_store_sales,
   a.total_web_sales,
   a.web_orders,
   a.price_category,
   a.web_spend_category,
   a.last_return_reason,
   SUM(a.total_web_sales) OVER (PARTITION BY a.ca_city) AS city_total_web_sales,
   ROW_NUMBER() OVER (PARTITION BY a.ca_city ORDER BY a.total_web_sales DESC) AS city_rank
FROM agg a
ORDER BY a.total_web_sales DESC
LIMIT 100
