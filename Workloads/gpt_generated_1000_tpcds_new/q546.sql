WITH catalog_cte AS (
   SELECT
       cs.cs_order_number,
       cs.cs_bill_customer_sk,
       cs.cs_ext_sales_price,
       cs.cs_net_profit,
       regexp_extract(c.c_email_address, '([^@]+)@([^\\.]+)\\.(.*)', 2) AS email_domain,
       CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_bucket,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
       regexp_split(c.c_customer_id, '') AS id_chars
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
     AND c.c_last_name LIKE '%son'
),
catalog_flat AS (
   SELECT
       cs_order_number,
       cs_bill_customer_sk,
       cs_ext_sales_price,
       cs_net_profit,
       email_domain,
       sales_bucket,
       full_name,
       ch
   FROM catalog_cte
   CROSS JOIN UNNEST(id_chars) AS t(ch)
),
web_cte AS (
   SELECT
       ws.ws_order_number,
       ws.ws_bill_customer_sk,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       regexp_extract(c.c_email_address, '([^@]+)@([^\\.]+)\\.(.*)', 2) AS email_domain,
       CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_bucket,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
       regexp_split(c.c_customer_id, '') AS id_chars
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
     AND c.c_last_name LIKE '%son'
),
web_flat AS (
   SELECT
       ws_order_number,
       ws_bill_customer_sk,
       ws_ext_sales_price,
       ws_net_profit,
       email_domain,
       sales_bucket,
       full_name,
       ch
   FROM web_cte
   CROSS JOIN UNNEST(id_chars) AS t(ch)
),
union_sales AS (
   SELECT cs_order_number AS order_number,
          cs_bill_customer_sk AS customer_sk,
          cs_ext_sales_price AS sale_amount,
          cs_net_profit,
          email_domain,
          sales_bucket,
          ch
   FROM catalog_flat
   UNION DISTINCT
   SELECT ws_order_number,
          ws_bill_customer_sk,
          ws_ext_sales_price,
          ws_net_profit,
          email_domain,
          sales_bucket,
          ch
   FROM web_flat
),
orders_without_returns AS (
   SELECT order_number,
          customer_sk,
          sale_amount,
          cs_net_profit AS net_profit,
          email_domain,
          sales_bucket,
          ch
   FROM union_sales
   EXCEPT
   SELECT cr_order_number,
          cr_refunded_customer_sk,
          cr_return_amount,
          cr_net_loss,
          CAST(NULL AS varchar),
          CAST(NULL AS varchar),
          CAST(NULL AS varchar)
   FROM catalog_returns
)
SELECT
    sales_bucket,
    email_domain,
    COUNT(DISTINCT customer_sk) AS num_customers,
    SUM(sale_amount) AS total_sales,
    SUM(net_profit) AS total_profit,
    COUNT(*) FILTER (WHERE ch = 'A') AS count_A_chars
FROM orders_without_returns
GROUP BY sales_bucket, email_domain
ORDER BY total_sales DESC
LIMIT 10
