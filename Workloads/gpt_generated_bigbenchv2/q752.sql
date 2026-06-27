WITH all_sales AS (
    SELECT i.i_category_id,
           i.i_category_name,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category_id,
           i.i_category_name,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_sales AS (
    SELECT i_category_id,
           i_category_name,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue,
           COUNT(DISTINCT customer_id) AS distinct_customer_cnt
    FROM all_sales
    GROUP BY i_category_id, i_category_name
),
category_rating AS (
    SELECT i.i_category_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT cs.i_category_name,
       cs.total_quantity,
       cs.total_revenue,
       cs.distinct_customer_cnt,
       cr.avg_rating
FROM category_sales cs
LEFT JOIN category_rating cr
  ON cs.i_category_id = cr.i_category_id
ORDER BY cs.total_revenue DESC
