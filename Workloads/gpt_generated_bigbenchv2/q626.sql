WITH item_details AS (
    SELECT i_item_id,
           i_category_id,
           i_category_name,
           i_price
    FROM items
),
store_sales_agg AS (
    SELECT ss.ss_item_id AS i_item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS i_item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
product_reviews_agg AS (
    SELECT pr.pr_item_id AS i_item_id,
           SUM(pr.pr_rating) AS rating_sum,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT id.i_category_id,
       id.i_category_name,
       SUM(COALESCE(ssa.store_quantity, 0)) AS total_store_quantity,
       SUM(COALESCE(wsa.web_quantity, 0)) AS total_web_quantity,
       SUM(COALESCE(ssa.store_revenue, 0)) AS total_store_revenue,
       SUM(COALESCE(wsa.web_revenue, 0)) AS total_web_revenue,
       SUM(COALESCE(ssa.store_customers, 0)) AS total_store_customers,
       SUM(COALESCE(wsa.web_customers, 0)) AS total_web_customers,
       SUM(COALESCE(pra.rating_sum, 0)) AS total_rating_sum,
       SUM(COALESCE(pra.review_count, 0)) AS total_review_count,
       CASE WHEN SUM(COALESCE(pra.review_count, 0)) > 0
            THEN SUM(COALESCE(pra.rating_sum, 0)) / SUM(COALESCE(pra.review_count, 0))
            ELSE NULL
       END AS avg_rating_per_category
FROM item_details id
LEFT JOIN store_sales_agg ssa
  ON id.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa
  ON id.i_item_id = wsa.i_item_id
LEFT JOIN product_reviews_agg pra
  ON id.i_item_id = pra.i_item_id
GROUP BY id.i_category_id, id.i_category_name
ORDER BY total_store_quantity + total_web_quantity DESC
LIMIT 10
