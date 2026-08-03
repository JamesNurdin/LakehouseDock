WITH full_sales AS (
   SELECT
       d.d_year,
       ss.ss_customer_sk,
       ws.ws_bill_customer_sk,
       ss.ss_net_paid,
       ws.ws_net_paid,
       d.d_date_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   FULL OUTER JOIN web_sales ws
       ON ss.ss_item_sk = ws.ws_item_sk
      AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
   WHERE d.d_year = 2001
),
agg_sales AS (
   SELECT
       d_year,
       COUNT(DISTINCT ss_customer_sk) AS uniq_store_cust,
       SUM(DISTINCT ss_net_paid) AS sum_distinct_store_net,
       COUNT(DISTINCT ws_bill_customer_sk) AS uniq_web_cust,
       SUM(DISTINCT ws_net_paid) AS sum_distinct_web_net
   FROM full_sales
   GROUP BY d_year
),
intersect_dates AS (
   SELECT d_date_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   INTERSECT
   SELECT d_date_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
store_counts AS (
   SELECT
       d.d_date_sk,
       'store' AS src,
       COUNT(DISTINCT ss.ss_customer_sk) AS cust_cnt,
       SUM(DISTINCT ss.ss_net_paid) AS total_net
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_date_sk IN (SELECT d_date_sk FROM intersect_dates)
   GROUP BY d.d_date_sk
),
web_counts AS (
   SELECT
       d.d_date_sk,
       'web' AS src,
       COUNT(DISTINCT ws.ws_bill_customer_sk) AS cust_cnt,
       SUM(DISTINCT ws.ws_net_paid) AS total_net
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_date_sk IN (SELECT d_date_sk FROM intersect_dates)
   GROUP BY d.d_date_sk
)
SELECT d_date_sk, src, cust_cnt, total_net
FROM store_counts
UNION ALL
SELECT d_date_sk, src, cust_cnt, total_net
FROM web_counts
ORDER BY d_date_sk, src
LIMIT 100
