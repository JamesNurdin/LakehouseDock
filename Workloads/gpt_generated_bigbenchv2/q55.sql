WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    INNER JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    INNER JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    SUM(COALESCE(ssa.total_store_quantity, 0) + COALESCE(wsa.total_web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(ssa.total_store_revenue, 0) + COALESCE(wsa.total_web_revenue, 0)) AS total_revenue,
    CASE
        WHEN SUM(COALESCE(rsa.review_count, 0)) = 0 THEN NULL
        ELSE SUM(rsa.avg_sentiment * rsa.review_count) / SUM(rsa.review_count)
    END AS avg_review_sentiment,
    SUM(COALESCE(rsa.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN reviews_agg rsa ON i.i_item_id = rsa.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
