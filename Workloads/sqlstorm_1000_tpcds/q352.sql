WITH sales_catalog AS (
 SELECT 
   cs.cs_sold_date_sk AS date_sk,
   cs.cs_bill_customer_sk AS customer_sk,
   cs.cs_order_number AS order_number,
   cs.cs_net_paid AS net_paid,
   cs.cs_quantity AS quantity,
   cs.cs_item_sk AS item_sk,
   'catalog' AS channel,
   cc.cc_name AS channel_name,
   cp.cp_type AS channel_type
 FROM catalog_sales cs
 LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
),
sales_store AS (
 SELECT
   ss.ss_sold_date_sk AS date_sk,
   ss.ss_customer_sk AS customer_sk,
   ss.ss_ticket_number AS order_number,
   ss.ss_net_paid AS net_paid,
   ss.ss_quantity AS quantity,
   ss.ss_item_sk AS item_sk,
   'store' AS channel,
   st.s_store_name AS channel_name,
   'store' AS channel_type
 FROM store_sales ss
 LEFT JOIN store st ON ss.ss_store_sk = st.s_store_sk
),
sales_web AS (
 SELECT
   ws.ws_sold_date_sk AS date_sk,
   ws.ws_bill_customer_sk AS customer_sk,
   ws.ws_order_number AS order_number,
   ws.ws_net_paid AS net_paid,
   ws.ws_quantity AS quantity,
   ws.ws_item_sk AS item_sk,
   'web' AS channel,
   wp.wp_url AS channel_name,
   'web' AS channel_type
 FROM web_sales ws
 LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
all_sales AS (
 SELECT * FROM sales_catalog
 UNION ALL
 SELECT * FROM sales_store
 UNION ALL
 SELECT * FROM sales_web
),
returns_catalog AS (
 SELECT 
   cr.cr_returned_date_sk AS date_sk,
   cr.cr_returning_customer_sk AS customer_sk,
   cr.cr_return_amount AS return_amount,
   cr.cr_reason_sk,
   'catalog' AS channel
 FROM catalog_returns cr
),
returns_store AS (
 SELECT 
   sr.sr_returned_date_sk AS date_sk,
   sr.sr_customer_sk AS customer_sk,
   sr.sr_return_amt AS return_amount,
   sr.sr_reason_sk,
   'store' AS channel
 FROM store_returns sr
),
returns_web AS (
 SELECT 
   wr.wr_returned_date_sk AS date_sk,
   wr.wr_refunded_customer_sk AS customer_sk,
   wr.wr_return_amt AS return_amount,
   wr.wr_reason_sk,
   'web' AS channel
 FROM web_returns wr
),
all_returns AS (
 SELECT * FROM returns_catalog
 UNION ALL
 SELECT * FROM returns_store
 UNION ALL
 SELECT * FROM returns_web
),
sales_aggregated AS (
 SELECT
   s.customer_sk,
   d.d_year,
   s.channel,
   s.channel_name,
   s.channel_type,
   SUM(s.net_paid) AS total_sales,
   COUNT(DISTINCT s.order_number) AS distinct_orders,
   SUM(s.quantity) AS total_quantity,
   COALESCE(r.total_return, 0) AS total_return,
   SUM(s.net_paid) - COALESCE(r.total_return, 0) AS net_revenue,
   COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS customer_full_name,
   CASE 
     WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' 
     ELSE 'Standard' 
   END AS customer_type,
   (SELECT COUNT(DISTINCT a2.item_sk) FROM all_sales a2 WHERE a2.customer_sk = s.customer_sk) AS distinct_items_purchased,
   CASE 
     WHEN (SUM(s.net_paid) - COALESCE(r.total_return, 0)) > 0 THEN 'Profit' 
     ELSE 'Loss' 
   END AS profit_indicator
 FROM all_sales s
 JOIN date_dim d ON s.date_sk = d.d_date_sk
 LEFT JOIN (
   SELECT 
     r.customer_sk,
     r.channel,
     d2.d_year,
     SUM(r.return_amount) AS total_return
   FROM all_returns r
   JOIN date_dim d2 ON r.date_sk = d2.d_date_sk
   GROUP BY r.customer_sk, r.channel, d2.d_year
 ) r ON s.customer_sk = r.customer_sk AND s.channel = r.channel AND d.d_year = r.d_year
 LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
 WHERE d.d_year BETWEEN 2001 AND 2002
   AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
   AND (s.channel_name IS NOT NULL OR s.channel_type IS NOT NULL)
 GROUP BY s.customer_sk, d.d_year, s.channel, s.channel_name, s.channel_type,
          c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, r.total_return
),
ranked_sales AS (
 SELECT
   *,
   ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY net_revenue DESC) AS channel_year_rank,
   SUM(net_revenue) OVER (PARTITION BY d_year) AS year_total_revenue
 FROM sales_aggregated
)
SELECT
   customer_sk,
   customer_full_name,
   customer_type,
   d_year,
   channel,
   channel_name,
   total_sales,
   total_quantity,
   distinct_orders,
   total_return,
   net_revenue,
   profit_indicator,
   distinct_items_purchased,
   channel_year_rank,
   year_total_revenue,
   CASE 
     WHEN net_revenue > year_total_revenue * 0.1 THEN 'Top10Percent'
     ELSE 'Other'
   END AS revenue_bucket
FROM ranked_sales
WHERE channel_year_rank <= 10
ORDER BY d_year, channel, channel_year_rank
