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
review_agg AS (
    SELECT pr_item_id,
           COUNT(*) AS review_count,
           SUM(pr_sentiment) AS sentiment_sum
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COALESCE(SUM(sa.total_store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(wa.total_web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(sa.total_store_quantity), 0) + COALESCE(SUM(wa.total_web_quantity), 0) AS total_quantity,
    COALESCE(SUM(r.review_count), 0) AS total_review_count,
    CASE WHEN COALESCE(SUM(r.review_count), 0) > 0
         THEN CAST(SUM(r.sentiment_sum) AS double) / SUM(r.review_count)
         ELSE NULL
    END AS avg_sentiment
FROM items i
LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity DESC
LIMIT 5
