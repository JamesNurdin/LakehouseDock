WITH all_sales AS (
   SELECT ss.ss_customer_sk AS cust_sk,
          d.d_year,
          ss.ss_ext_sales_price AS sales,
          ss.ss_net_profit AS profit,
          'store' AS channel
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   UNION ALL
   SELECT ws.ws_bill_customer_sk AS cust_sk,
          d.d_year,
          ws.ws_ext_sales_price AS sales,
          ws.ws_net_profit AS profit,
          'web' AS channel
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   UNION ALL
   SELECT cs.cs_bill_customer_sk AS cust_sk,
          d.d_year,
          cs.cs_ext_sales_price AS sales,
          cs.cs_net_profit AS profit,
          'catalog' AS channel
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
),
cust_info AS (
   SELECT c.c_customer_sk,
          c.c_first_name,
          c.c_last_name,
          c.c_email_address
   FROM customer c
)
SELECT ci.c_customer_sk,
       ci.c_first_name,
       ci.c_last_name,
       ci.c_email_address,
       s.d_year,
       s.channel,
       SUM(s.sales) AS total_sales,
       SUM(s.profit) AS total_profit
FROM all_sales s
JOIN cust_info ci ON s.cust_sk = ci.c_customer_sk
WHERE s.d_year = 2002
GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.c_email_address, s.d_year, s.channel
ORDER BY total_profit DESC
LIMIT 50
