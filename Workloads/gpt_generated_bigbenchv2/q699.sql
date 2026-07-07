WITH sales_union AS (
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
    SELECT su.item_id,
           SUM(su.quantity) AS total_quantity,
           COUNT(DISTINCT su.customer_id) AS distinct_customer_count
    FROM sales_union su
    GROUP BY su.item_id
),
review_stats AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(its.total_quantity) AS category_total_quantity,
       AVG(i.i_price) AS avg_item_price,
       SUM(its.distinct_customer_count) AS category_customer_count,
       AVG(rs.avg_sentiment) AS avg_category_sentiment,
       SUM(rs.review_count) AS total_reviews
FROM items i
LEFT JOIN item_sales its ON i.i_item_id = its.item_id
LEFT JOIN review_stats rs ON i.i_item_id = rs.item_id
WHERE its.total_quantity IS NOT NULL
GROUP BY i.i_category_id, i.i_category
ORDER BY category_total_quantity DESC
LIMIT 10
