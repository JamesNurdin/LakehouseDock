WITH sales_union AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(su.quantity) AS total_quantity,
           SUM(su.quantity * i.i_price) AS total_revenue
    FROM sales_union su
    JOIN items i ON su.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_by_category AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT sbc.i_category_id,
       sbc.i_category,
       sbc.total_quantity,
       sbc.total_revenue,
       rbc.avg_sentiment,
       rbc.review_count
FROM sales_by_category sbc
LEFT JOIN reviews_by_category rbc ON sbc.i_category_id = rbc.i_category_id
ORDER BY sbc.total_quantity DESC
LIMIT 10
