WITH store_metrics AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(i.i_price * ss.ss_quantity) AS store_revenue,
        0 AS web_quantity,
        0 AS web_revenue,
        0 AS rating_sum,
        0 AS rating_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_metrics AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        0 AS store_quantity,
        0 AS store_revenue,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(i.i_price * ws.ws_quantity) AS web_revenue,
        0 AS rating_sum,
        0 AS rating_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_metrics AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        0 AS store_quantity,
        0 AS store_revenue,
        0 AS web_quantity,
        0 AS web_revenue,
        SUM(pr.pr_rating) AS rating_sum,
        COUNT(pr.pr_review_id) AS rating_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
combined AS (
    SELECT * FROM store_metrics
    UNION ALL
    SELECT * FROM web_metrics
    UNION ALL
    SELECT * FROM review_metrics
)
SELECT
    i_category_id,
    i_category_name,
    SUM(store_quantity) AS total_store_quantity,
    SUM(store_revenue) AS total_store_revenue,
    SUM(web_quantity) AS total_web_quantity,
    SUM(web_revenue) AS total_web_revenue,
    CASE WHEN SUM(rating_count) = 0 THEN NULL ELSE SUM(rating_sum) / SUM(rating_count) END AS average_rating,
    SUM(rating_count) AS total_review_count
FROM combined
GROUP BY i_category_id, i_category_name
ORDER BY total_store_revenue DESC
LIMIT 20
