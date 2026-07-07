WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_item_sales AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_sentiment AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(si.total_store_quantity, 0) AS store_quantity,
    COALESCE(si.total_store_revenue, 0) AS store_revenue,
    COALESCE(wi.total_web_quantity, 0) AS web_quantity,
    COALESCE(wi.total_web_revenue, 0) AS web_revenue,
    COALESCE(sen.avg_sentiment, 0) AS avg_review_sentiment,
    COALESCE(sen.review_count, 0) AS review_count
FROM stores s
JOIN store_item_sales si ON s.s_store_id = si.ss_store_id
JOIN items i ON si.ss_item_id = i.i_item_id
LEFT JOIN web_item_sales wi ON i.i_item_id = wi.ws_item_id
LEFT JOIN item_sentiment sen ON i.i_item_id = sen.pr_item_id
ORDER BY (COALESCE(si.total_store_quantity, 0) + COALESCE(wi.total_web_quantity, 0)) DESC
LIMIT 100
