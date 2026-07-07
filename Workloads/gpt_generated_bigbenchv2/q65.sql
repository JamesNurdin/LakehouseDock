WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT s.item_id,
           SUM(s.quantity) AS total_quantity
    FROM sales s
    GROUP BY s.item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(sa.total_quantity) AS total_quantity_sold,
       SUM(sa.total_quantity * i.i_price) AS total_revenue,
       AVG(ra.avg_sentiment) AS avg_item_sentiment,
       SUM(ra.review_count) AS total_reviews
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
