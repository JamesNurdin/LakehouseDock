WITH
    store_sales_agg AS (
        SELECT ss.ss_store_id,
               ss.ss_item_id,
               SUM(ss.ss_quantity) AS store_quantity,
               COUNT(DISTINCT ss.ss_customer_id) AS store_customers
        FROM store_sales ss
        GROUP BY ss.ss_store_id, ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT ws.ws_item_id,
               SUM(ws.ws_quantity) AS web_quantity,
               COUNT(DISTINCT ws.ws_customer_id) AS web_customers
        FROM web_sales ws
        GROUP BY ws.ws_item_id
    ),
    item_reviews_agg AS (
        SELECT pr.pr_item_id,
               AVG(pr.pr_rating) AS avg_rating,
               COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT s.s_store_name,
       i.i_category_name,
       SUM(COALESCE(ssa.store_quantity, 0)) AS total_store_quantity,
       SUM(COALESCE(wsa.web_quantity, 0))   AS total_web_quantity,
       AVG(COALESCE(ira.avg_rating, 0))     AS avg_item_rating,
       SUM(COALESCE(ira.review_count, 0))  AS total_review_count,
       SUM(COALESCE(ssa.store_customers, 0)) AS total_store_customers,
       SUM(COALESCE(wsa.web_customers, 0))   AS total_web_customers
FROM items i
JOIN store_sales_agg ssa
  ON i.i_item_id = ssa.ss_item_id
JOIN stores s
  ON ssa.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wsa
  ON i.i_item_id = wsa.ws_item_id
LEFT JOIN item_reviews_agg ira
  ON i.i_item_id = ira.pr_item_id
GROUP BY s.s_store_name, i.i_category_name
ORDER BY s.s_store_name, i.i_category_name
