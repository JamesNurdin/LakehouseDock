WITH combined_sales AS (
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
    FROM combined_sales
    GROUP BY item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_price,
       AVG(r.avg_sentiment) AS avg_review_sentiment,
       SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN sales_agg s
    ON i.i_item_id = s.item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
