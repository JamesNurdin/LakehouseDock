WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_item_price,
       AVG(r.avg_sentiment) AS avg_review_sentiment,
       SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
