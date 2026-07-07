WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS unique_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS unique_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        SUM(pr.pr_sentiment) AS sum_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(COALESCE(ssa.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wsa.web_quantity, 0)) AS total_web_quantity,
    COALESCE(SUM(ssa.store_revenue), 0.0) + COALESCE(SUM(wsa.web_revenue), 0.0) AS total_revenue,
    SUM(COALESCE(ssa.unique_store_customers, 0)) AS total_unique_store_customers,
    SUM(COALESCE(wsa.unique_web_customers, 0)) AS total_unique_web_customers,
    CASE
        WHEN SUM(COALESCE(ra.review_count, 0)) = 0 THEN NULL
        ELSE SUM(COALESCE(ra.sum_sentiment, 0)) / SUM(COALESCE(ra.review_count, 0))
    END AS avg_review_sentiment,
    SUM(COALESCE(ra.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.item_id = i.i_item_id
LEFT JOIN reviews_agg ra ON ra.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
