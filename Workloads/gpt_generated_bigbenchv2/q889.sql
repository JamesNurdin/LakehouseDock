WITH store_sales_agg AS (
    SELECT
        ss_item_id AS item_id,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id AS item_id,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_reviews_agg AS (
    SELECT
        pr_item_id AS item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity_sold,
    CASE
        WHEN SUM(r.review_count) > 0 THEN SUM(r.avg_sentiment * r.review_count) / SUM(r.review_count)
        ELSE NULL
    END AS avg_review_sentiment,
    SUM(r.review_count) AS total_review_count
FROM items i
LEFT JOIN store_sales_agg s ON s.item_id = i.i_item_id
LEFT JOIN web_sales_agg w ON w.item_id = i.i_item_id
LEFT JOIN item_reviews_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
