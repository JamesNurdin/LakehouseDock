WITH store_sales_agg AS (
    SELECT ss_item_id, SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id, SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id, AVG(pr_sentiment) AS avg_sentiment, COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COALESCE(SUM(sa.store_qty), 0) + COALESCE(SUM(wa.web_qty), 0) AS total_quantity_sold,
    AVG(i.i_price) AS avg_price,
    AVG(r.avg_sentiment) AS avg_review_sentiment,
    SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
