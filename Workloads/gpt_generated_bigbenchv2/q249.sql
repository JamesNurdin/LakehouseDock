WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_customer_id AS customer_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_customer_id AS customer_id
    FROM web_sales
),
item_sales AS (
    SELECT s.item_id,
           SUM(s.quantity) AS total_quantity,
           COUNT(DISTINCT s.customer_id) AS distinct_customer_count
    FROM sales s
    GROUP BY s.item_id
),
item_reviews AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_name,
       i.i_name,
       COALESCE(isales.total_quantity, 0) AS total_quantity,
       COALESCE(isales.distinct_customer_count, 0) AS distinct_customer_count,
       COALESCE(irev.avg_rating, 0) AS avg_rating,
       COALESCE(irev.review_count, 0) AS review_count,
       COALESCE(isales.total_quantity, 0) * i.i_price AS estimated_revenue
FROM items i
LEFT JOIN item_sales isales
       ON i.i_item_id = isales.item_id
LEFT JOIN item_reviews irev
       ON i.i_item_id = irev.item_id
WHERE i.i_category_name IS NOT NULL
ORDER BY estimated_revenue DESC, i.i_category_name
LIMIT 20
