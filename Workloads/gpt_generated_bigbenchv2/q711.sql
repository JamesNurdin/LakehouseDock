WITH store_rev AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_rev AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
rating AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    sr.i_category_id,
    sr.i_category_name,
    sr.store_quantity,
    sr.store_revenue,
    COALESCE(wr.web_quantity, 0) AS web_quantity,
    COALESCE(wr.web_revenue, 0) AS web_revenue,
    r.avg_rating,
    r.review_count
FROM store_rev sr
JOIN stores s ON sr.ss_store_id = s.s_store_id
LEFT JOIN web_rev wr ON sr.i_category_id = wr.i_category_id
LEFT JOIN rating r ON sr.i_category_id = r.i_category_id
ORDER BY s.s_store_name, sr.store_revenue DESC
