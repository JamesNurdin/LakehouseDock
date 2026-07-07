WITH all_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM all_sales
    GROUP BY item_id
),
review_stats AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       SUM(sa.total_quantity) AS category_total_quantity,
       AVG(rs.avg_sentiment) AS category_avg_sentiment,
       COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN review_stats rs ON i.i_item_id = rs.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY category_total_quantity DESC
LIMIT 10
