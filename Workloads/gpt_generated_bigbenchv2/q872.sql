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
    SELECT item_id,
           SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY item_id
),
reviews_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       SUM(sa.total_quantity) AS total_quantity_sold,
       SUM(COALESCE(r.avg_sentiment, 0) * sa.total_quantity) / NULLIF(SUM(sa.total_quantity), 0) AS weighted_avg_sentiment,
       COUNT(r.item_id) AS items_with_reviews,
       AVG(i.i_price) AS avg_item_price
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
