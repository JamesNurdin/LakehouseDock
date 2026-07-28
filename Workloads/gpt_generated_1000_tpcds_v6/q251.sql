WITH base AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_bill_customer_sk,
       cs.cs_item_sk,
       cs.cs_ext_sales_price,
       cs.cs_net_profit,
       d.d_year,
       t.t_hour,
       cust.c_first_name,
       cust.c_last_name,
       s.s_store_name,
       s.s_state,
       wp.wp_type,
       wp.wp_url,
       (
         SELECT MAX(wr.wr_return_amt)
         FROM web_returns wr
         WHERE wr.wr_returning_customer_sk = cust.c_customer_sk
           AND wr.wr_returned_date_sk = d.d_date_sk
           AND wr.wr_returned_time_sk = t.t_time_sk
       ) AS max_return_amt
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer cust
     ON cs.cs_bill_customer_sk = cust.c_customer_sk
   JOIN store_sales ss
     ON ss.ss_customer_sk = cust.c_customer_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN web_page wp
     ON wp.wp_customer_sk = cust.c_customer_sk
   WHERE d.d_year = 2001
     AND t.t_hour BETWEEN 9 AND 17
     AND s.s_state = 'CA'
     AND cs.cs_ext_sales_price > 100
     AND EXISTS (
         SELECT 1
         FROM web_returns wr
         WHERE wr.wr_returning_customer_sk = cust.c_customer_sk
           AND wr.wr_returned_date_sk = d.d_date_sk
           AND wr.wr_returned_time_sk = t.t_time_sk
           AND wr.wr_return_amt > 50
     )
)

SELECT *
FROM (
   SELECT
       cs_sold_date_sk,
       cs_sold_time_sk,
       cs_bill_customer_sk,
       cs_item_sk,
       cs_ext_sales_price,
       cs_net_profit,
       d_year,
       t_hour,
       c_first_name,
       c_last_name,
       s_store_name,
       s_state,
       wp_type,
       wp_url,
       max_return_amt,
       'profit_rank' AS rank_category,
       RANK() OVER (PARTITION BY d_year ORDER BY cs_net_profit DESC) AS rank_value
   FROM base
   WHERE cs_net_profit IS NOT NULL

   UNION ALL

   SELECT
       cs_sold_date_sk,
       cs_sold_time_sk,
       cs_bill_customer_sk,
       cs_item_sk,
       cs_ext_sales_price,
       cs_net_profit,
       d_year,
       t_hour,
       c_first_name,
       c_last_name,
       s_store_name,
       s_state,
       wp_type,
       wp_url,
       max_return_amt,
       'return_rank' AS rank_category,
       RANK() OVER (PARTITION BY d_year ORDER BY max_return_amt DESC) AS rank_value
   FROM base
   WHERE max_return_amt IS NOT NULL
) ordered
ORDER BY rank_category, rank_value
LIMIT 100
