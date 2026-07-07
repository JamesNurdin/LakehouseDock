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
review_agg AS (
    SELECT pr_item_id AS item_id,
           COUNT(*) AS review_count,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    SUM(COALESCE(sa.total_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(ra.review_count, 0)) AS total_review_count,
    CASE WHEN SUM(COALESCE(ra.review_count, 0)) > 0
         THEN SUM(COALESCE(ra.avg_sentiment * ra.review_count, 0)) / SUM(COALESCE(ra.review_count, 0))
         ELSE NULL
    END AS avg_sentiment_per_category
FROM items i
LEFT JOIN sales_agg sa
    ON sa.item_id = i.i_item_id
LEFT JOIN review_agg ra
    ON ra.item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
