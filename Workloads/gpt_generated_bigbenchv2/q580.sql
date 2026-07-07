WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           SUM(pr_sentiment) AS sum_sentiment,
           COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COALESCE(SUM(sa.total_store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(wa.total_web_quantity), 0) AS total_web_quantity,
    CASE WHEN SUM(r.review_count) > 0 THEN SUM(r.sum_sentiment) / SUM(r.review_count) END AS avg_review_sentiment,
    COALESCE(SUM(r.review_count), 0) AS total_review_count,
    AVG(i.i_price) AS avg_item_price
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.pr_item_id
GROUP BY
    i.i_category_id,
    i.i_category
ORDER BY
    total_store_quantity DESC,
    total_web_quantity DESC
