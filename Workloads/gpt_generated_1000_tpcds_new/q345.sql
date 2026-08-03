WITH high_sales AS (
   SELECT s.s_store_id,
          SUM(ss.ss_net_paid) AS total_net_paid,
          CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'HIGH' ELSE 'OTHER' END AS revenue_category
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450845
   GROUP BY s.s_store_id
   HAVING SUM(ss.ss_net_paid) > 100000
),
medium_sales AS (
   SELECT s.s_store_id,
          SUM(ss.ss_net_paid) AS total_net_paid,
          CASE WHEN SUM(ss.ss_net_paid) > 50000 THEN 'MEDIUM' ELSE 'OTHER' END AS revenue_category
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450845
   GROUP BY s.s_store_id
   HAVING SUM(ss.ss_net_paid) BETWEEN 50001 AND 100000
),
promo_excluded AS (
   SELECT s.s_store_id,
          SUM(ss.ss_net_paid) AS total_net_paid,
          'EXCLUDED' AS revenue_category
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE p.p_cost > 1000
   GROUP BY s.s_store_id
)
SELECT s_store_id,
       total_net_paid,
       revenue_category
FROM (
   SELECT s_store_id, total_net_paid, revenue_category FROM high_sales
   UNION
   SELECT s_store_id, total_net_paid, revenue_category FROM medium_sales
)
EXCEPT
SELECT s_store_id, total_net_paid, revenue_category FROM promo_excluded
ORDER BY total_net_paid DESC
LIMIT 100
