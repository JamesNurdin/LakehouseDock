WITH sales_cte AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_city,
       ca.ca_city AS cust_city,
       cd.cd_gender,
       r.r_reason_desc,
       ss.ss_ticket_number AS ticket_number,
       ss.ss_ext_sales_price AS sales_amount,
       0.0 AS return_amount,
       ss.ss_sold_date_sk
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE s.s_city = 'Liberty'
     AND ca.ca_city = 'Fairview'
     AND cd.cd_gender = 'M'
     AND r.r_reason_desc = 'Damaged'
     AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
     AND ss.ss_ext_sales_price > 100
),
returns_cte AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_city,
       ca.ca_city AS cust_city,
       cd.cd_gender,
       r.r_reason_desc,
       sr.sr_ticket_number AS ticket_number,
       0.0 AS sales_amount,
       sr.sr_return_amt_inc_tax AS return_amount,
       sr.sr_returned_date_sk
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE s.s_city = 'Liberty'
     AND ca.ca_city = 'Fairview'
     AND cd.cd_gender = 'M'
     AND r.r_reason_desc = 'Damaged'
     AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
     AND sr.sr_return_amt_inc_tax > 100
)
SELECT
   s_store_sk,
   s_store_name,
   s_city,
   cust_city,
   cd_gender,
   r_reason_desc,
   ticket_number,
   sales_amount,
   return_amount,
   (sales_amount - return_amount) AS net_amount,
   ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY (sales_amount - return_amount) DESC) AS store_net_rank
FROM (
   SELECT * FROM sales_cte
   UNION ALL
   SELECT * FROM returns_cte
) combined
ORDER BY net_amount DESC
LIMIT 100
