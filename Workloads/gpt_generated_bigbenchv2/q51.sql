WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           i_price AS price,
           ss_customer_id AS customer_id
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           i_price AS price,
           ws_customer_id AS customer_id
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
),
item_sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM combined_sales
    GROUP BY item_id
),
item_ratings_agg AS (
    SELECT i.i_item_id AS item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category_name,
       SUM(is_agg.total_quantity) AS category_quantity,
       SUM(is_agg.total_revenue) AS category_revenue,
       AVG(COALESCE(ir_agg.avg_rating, 0)) AS category_avg_rating,
       SUM(COALESCE(ir_agg.review_count, 0)) AS category_review_count,
       COUNT(DISTINCT is_agg.item_id) AS distinct_items_sold,
       SUM(is_agg.distinct_customers) AS total_distinct_customers
FROM item_sales_agg is_agg
JOIN items i ON is_agg.item_id = i.i_item_id
LEFT JOIN item_ratings_agg ir_agg ON is_agg.item_id = ir_agg.item_id
GROUP BY i.i_category_name
ORDER BY category_revenue DESC
LIMIT 10
