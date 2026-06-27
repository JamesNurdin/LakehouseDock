WITH store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_qty,
           COUNT(DISTINCT ss_customer_id) AS store_customers,
           COUNT(DISTINCT ss_store_id) AS store_count
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_qty,
           COUNT(DISTINCT ws_customer_id) AS web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
product_reviews_agg AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity,
       (COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) * i.i_price AS total_revenue,
       pr.avg_rating,
       pr.review_count,
       COALESCE(ss.store_customers, 0) + COALESCE(ws.web_customers, 0) AS total_customers,
       COALESCE(ss.store_count, 0) AS store_count
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
LEFT JOIN product_reviews_agg pr ON i.i_item_id = pr.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
