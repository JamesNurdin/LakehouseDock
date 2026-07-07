WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        SUM(pr.pr_sentiment) AS sentiment_sum,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COALESCE(SUM(sa.store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(sa.store_revenue), 0) AS total_store_revenue,
    COALESCE(SUM(wa.web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(wa.web_revenue), 0) AS total_web_revenue,
    COALESCE(SUM(sa.store_quantity) + SUM(wa.web_quantity), 0) AS total_quantity,
    COALESCE(SUM(sa.store_revenue) + SUM(wa.web_revenue), 0) AS total_revenue,
    CASE WHEN SUM(ra.review_count) > 0
        THEN SUM(ra.sentiment_sum) / SUM(ra.review_count)
        ELSE NULL
    END AS avg_sentiment,
    COALESCE(SUM(ra.review_count), 0) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg sa
    ON i.i_item_id = sa.item_id
LEFT JOIN web_sales_agg wa
    ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra
    ON i.i_item_id = ra.item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
