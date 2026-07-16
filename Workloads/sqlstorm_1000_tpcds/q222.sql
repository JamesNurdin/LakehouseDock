WITH
store_sales_agg AS (
 SELECT ss.ss_sold_date_sk AS date_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
 FROM store_sales ss
 GROUP BY ss.ss_sold_date_sk
),
catalog_sales_agg AS (
 SELECT cs.cs_sold_date_sk AS date_sk,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
 FROM catalog_sales cs
 GROUP BY cs.cs_sold_date_sk
),
web_sales_agg AS (
 SELECT ws.ws_sold_date_sk AS date_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
 FROM web_sales ws
 GROUP BY ws.ws_sold_date_sk
),
returns_agg AS (
 SELECT d.d_date,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss
 FROM date_dim d
 LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
 LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
 LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
 WHERE d.d_year = 2001
 GROUP BY d.d_date
),
date_agg AS (
 SELECT d.d_date,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq
 FROM date_dim d
 WHERE d.d_year = 2001
),
customer_spend AS (
 SELECT c.c_customer_id,
        COALESCE(ss.ss_spent,0) + COALESCE(ws.ws_spent,0) + COALESCE(cs.cs_spent,0) AS total_spent
 FROM customer c
 LEFT JOIN (
   SELECT ss_customer_sk AS cust_sk, SUM(ss_net_paid) AS ss_spent
   FROM store_sales
   GROUP BY ss_customer_sk
 ) ss ON ss.cust_sk = c.c_customer_sk
 LEFT JOIN (
   SELECT ws_bill_customer_sk AS cust_sk, SUM(ws_net_paid) AS ws_spent
   FROM web_sales
   GROUP BY ws_bill_customer_sk
 ) ws ON ws.cust_sk = c.c_customer_sk
 LEFT JOIN (
   SELECT cs_bill_customer_sk AS cust_sk, SUM(cs_net_paid) AS cs_spent
   FROM catalog_sales
   GROUP BY cs_bill_customer_sk
 ) cs ON cs.cust_sk = c.c_customer_sk
),
top_customers AS (
 SELECT c_customer_id
 FROM customer_spend
 WHERE total_spent > 10000
 ORDER BY total_spent DESC
 LIMIT 10
)
SELECT da.d_date,
       da.d_year,
       da.d_month_seq,
       COALESCE(ssa.store_net_paid,0) AS store_net_paid,
       COALESCE(ssa.store_net_profit,0) AS store_net_profit,
       COALESCE(csa.catalog_net_paid,0) AS catalog_net_paid,
       COALESCE(csa.catalog_net_profit,0) AS catalog_net_profit,
       COALESCE(wsa.web_net_paid,0) AS web_net_paid,
       COALESCE(wsa.web_net_profit,0) AS web_net_profit,
       COALESCE(r.store_net_loss,0) AS store_net_loss,
       COALESCE(r.catalog_net_loss,0) AS catalog_net_loss,
       COALESCE(r.web_net_loss,0) AS web_net_loss,
       (COALESCE(ssa.store_net_paid,0) - COALESCE(r.store_net_loss,0)) AS store_net_contrib,
       (COALESCE(csa.catalog_net_paid,0) - COALESCE(r.catalog_net_loss,0)) AS catalog_net_contrib,
       (COALESCE(wsa.web_net_paid,0) - COALESCE(r.web_net_loss,0)) AS web_net_contrib,
       CASE
         WHEN (COALESCE(ssa.store_net_paid,0) - COALESCE(r.store_net_loss,0)) >= GREATEST(COALESCE(csa.catalog_net_paid,0) - COALESCE(r.catalog_net_loss,0), COALESCE(wsa.web_net_paid,0) - COALESCE(r.web_net_loss,0)) THEN 'Store'
         WHEN (COALESCE(csa.catalog_net_paid,0) - COALESCE(r.catalog_net_loss,0)) >= GREATEST(COALESCE(ssa.store_net_paid,0) - COALESCE(r.store_net_loss,0), COALESCE(wsa.web_net_paid,0) - COALESCE(r.web_net_loss,0)) THEN 'Catalog'
         ELSE 'Web'
       END AS leading_channel,
       (SELECT array_agg(tc.c_customer_id) FROM top_customers tc) AS top_10_customers
FROM date_agg da
LEFT JOIN store_sales_agg ssa ON ssa.date_sk = da.d_date_sk
LEFT JOIN catalog_sales_agg csa ON csa.date_sk = da.d_date_sk
LEFT JOIN web_sales_agg wsa ON wsa.date_sk = da.d_date_sk
LEFT JOIN returns_agg r ON r.d_date = da.d_date
ORDER BY da.d_date
