WITH sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS total_quantity_sold
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_name,
       i.i_price,
       s.total_quantity_sold,
       r.avg_sentiment,
       r.review_count
FROM items i
JOIN sales_agg s ON s.item_id = i.i_item_id
JOIN reviews_agg r ON r.item_id = i.i_item_id
ORDER BY s.total_quantity_sold DESC
LIMIT 10
