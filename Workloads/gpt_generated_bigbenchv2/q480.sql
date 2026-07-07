WITH store_agg AS (
    SELECT ss_item_id, SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id, SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id, AVG(pr_sentiment) AS avg_sentiment, COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COALESCE(SUM(sa.store_qty), 0) AS total_store_quantity,
    COALESCE(SUM(wa.web_qty), 0) AS total_web_quantity,
    CASE WHEN SUM(ra.review_cnt) > 0
        THEN SUM(ra.avg_sentiment * ra.review_cnt) / SUM(ra.review_cnt)
        ELSE NULL
    END AS avg_category_sentiment,
    SUM(ra.review_cnt) AS total_reviews
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY (COALESCE(SUM(sa.store_qty), 0) + COALESCE(SUM(wa.web_qty), 0)) DESC
LIMIT 10
