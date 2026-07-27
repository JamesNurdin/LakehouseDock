WITH preferred_sales AS (
   SELECT s.s_store_name,
          c.c_customer_id,
          SUM(ss.ss_net_paid) AS total_net_paid,
          COUNT(*) AS transaction_count,
          'Preferred' AS customer_segment
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE c.c_preferred_cust_flag = 'Y'
     AND cd.cd_credit_rating = 'Good'
   GROUP BY s.s_store_name, c.c_customer_id
),
non_preferred_sales AS (
   SELECT s.s_store_name,
          c.c_customer_id,
          SUM(ss.ss_net_paid) AS total_net_paid,
          COUNT(*) AS transaction_count,
          'NonPreferred' AS customer_segment
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE c.c_preferred_cust_flag = 'N'
     AND cd.cd_credit_rating = 'Low Risk'
   GROUP BY s.s_store_name, c.c_customer_id
)
SELECT s_store_name,
       c_customer_id,
       total_net_paid,
       transaction_count,
       customer_segment
FROM preferred_sales
UNION ALL
SELECT s_store_name,
       c_customer_id,
       total_net_paid,
       transaction_count,
       customer_segment
FROM non_preferred_sales
ORDER BY total_net_paid DESC
LIMIT 100
