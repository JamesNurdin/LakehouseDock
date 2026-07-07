WITH sales_union AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM sales_union
    GROUP BY item_id
),
reviews_agg AS (
    SELECT pr_item_id AS item_id, AVG(pr_sentiment) AS avg_sentiment, COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_category_id,
       COALESCE(s.total_quantity, 0) AS total_quantity_sold,
       COALESCE(r.avg_sentiment, 0) AS avg_review_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN sales_agg s ON i.i_item_id = s.item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
ORDER BY total_quantity_sold DESC, avg_review_sentiment DESC
LIMIT 10
