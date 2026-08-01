WITH filtered_customers AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           CASE
               WHEN c.c_birth_country = 'BHUTAN' THEN 'Region_A'
               WHEN c.c_birth_country = 'BARBADOS' THEN 'Region_B'
               ELSE 'Other'
           END AS region
    FROM customer c
    WHERE EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_customer_sk = c.c_customer_sk
          AND ss.ss_net_profit > 0
    )
),
sales_agg AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           SUM(cs.cs_net_paid) AS total_net_paid,
           COUNT(*) AS order_cnt,
           ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY cs.cs_bill_customer_sk
    HAVING SUM(cs.cs_net_paid) > 1000
),
web_sales_agg AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_net_paid) AS total_net_paid,
           COUNT(*) AS order_cnt,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY ws.ws_bill_customer_sk
    HAVING SUM(ws.ws_net_paid) > 1000
),
full_join_sales AS (
    SELECT COALESCE(ss.customer_sk, wh.w_warehouse_sk) AS key_id,
           ss.total_net_paid AS store_total,
           wh.total_net_paid AS warehouse_total
    FROM (
        SELECT ss.ss_customer_sk AS customer_sk,
               SUM(ss.ss_net_paid) AS total_net_paid
        FROM store_sales ss
        GROUP BY ss.ss_customer_sk
    ) ss
    FULL OUTER JOIN (
        SELECT w.w_warehouse_sk,
               SUM(cs.cs_net_paid) AS total_net_paid
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_sk
    ) wh
      ON ss.customer_sk = wh.w_warehouse_sk
)
SELECT a.customer_sk,
       a.total_net_paid,
       CASE WHEN a.total_net_paid > 5000 THEN 'High' ELSE 'Low' END AS tier,
       a.sales_rank,
       a.region
FROM (
    SELECT sa.customer_sk,
           sa.total_net_paid,
           sa.sales_rank,
           fc.region
    FROM sales_agg sa
    JOIN filtered_customers fc ON sa.customer_sk = fc.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM full_join_sales fjs WHERE fjs.key_id = sa.customer_sk
    )
) a
INTERSECT
SELECT b.customer_sk,
       b.total_net_paid,
       CASE WHEN b.total_net_paid > 5000 THEN 'High' ELSE 'Low' END AS tier,
       b.sales_rank,
       b.region
FROM (
    SELECT wa.customer_sk,
           wa.total_net_paid,
           wa.sales_rank,
           fc2.region
    FROM web_sales_agg wa
    JOIN filtered_customers fc2 ON wa.customer_sk = fc2.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM full_join_sales fjs WHERE fjs.key_id = wa.customer_sk
    )
) b
ORDER BY total_net_paid DESC
LIMIT 100
