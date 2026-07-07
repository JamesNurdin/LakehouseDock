WITH web_sales_agg AS (
    SELECT ws_customer_id,
           sum(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_customer_id
),
store_customers AS (
    SELECT ss_store_id,
           ss_customer_id
    FROM store_sales
    GROUP BY ss_store_id, ss_customer_id
),
store_agg AS (
    SELECT ss_store_id,
           sum(ss_quantity) AS total_store_quantity,
           count(DISTINCT ss_customer_id) AS distinct_customers
    FROM store_sales
    GROUP BY ss_store_id
),
store_web_agg AS (
    SELECT sc.ss_store_id,
           sum(ws_agg.web_quantity) AS total_web_quantity
    FROM store_customers sc
    LEFT JOIN web_sales_agg ws_agg
           ON sc.ss_customer_id = ws_agg.ws_customer_id
    GROUP BY sc.ss_store_id
)
SELECT s.s_store_id,
       s.s_store_name,
       sa.total_store_quantity,
       sa.distinct_customers,
       coalesce(swa.total_web_quantity, 0) AS total_web_quantity_for_store_customers
FROM store_agg sa
JOIN stores s
  ON sa.ss_store_id = s.s_store_id
LEFT JOIN store_web_agg swa
  ON sa.ss_store_id = swa.ss_store_id
ORDER BY sa.total_store_quantity DESC
LIMIT 10
