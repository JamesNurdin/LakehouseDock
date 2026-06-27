WITH category_ratings AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_store_sales AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_web_sales AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_customers AS (
    SELECT c.i_category_id,
           c.i_category_name,
           COUNT(DISTINCT c.cust_id) AS distinct_total_customers
    FROM (
        SELECT i.i_category_id,
               i.i_category_name,
               ss.ss_customer_id AS cust_id
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT i.i_category_id,
               i.i_category_name,
               ws.ws_customer_id AS cust_id
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ) c
    GROUP BY c.i_category_id, c.i_category_name
)
SELECT cr.i_category_id,
       cr.i_category_name,
       cr.avg_rating,
       cr.review_count,
       cs.total_store_quantity,
       cs.distinct_store_customers,
       cw.total_web_quantity,
       cw.distinct_web_customers,
       cc.distinct_total_customers,
       (COALESCE(cs.total_store_quantity, 0) + COALESCE(cw.total_web_quantity, 0)) AS total_quantity_sold
FROM category_ratings cr
LEFT JOIN category_store_sales cs
  ON cr.i_category_id = cs.i_category_id
 AND cr.i_category_name = cs.i_category_name
LEFT JOIN category_web_sales cw
  ON cr.i_category_id = cw.i_category_id
 AND cr.i_category_name = cw.i_category_name
LEFT JOIN category_customers cc
  ON cr.i_category_id = cc.i_category_id
 AND cr.i_category_name = cc.i_category_name
ORDER BY cr.avg_rating DESC
LIMIT 20
