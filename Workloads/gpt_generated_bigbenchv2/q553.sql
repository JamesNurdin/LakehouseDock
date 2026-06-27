WITH
    store_item_sales AS (
        SELECT
            i.i_item_id,
            SUM(ss.ss_quantity) AS total_store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
        FROM store_sales ss
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    web_item_sales AS (
        SELECT
            i.i_item_id,
            SUM(ws.ws_quantity) AS total_web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
        FROM web_sales ws
        JOIN items i
            ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    item_reviews AS (
        SELECT
            i.i_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        JOIN items i
            ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(s.total_store_quantity, 0) AS store_quantity,
    COALESCE(s.total_store_revenue, 0) AS store_revenue,
    COALESCE(w.total_web_quantity, 0) AS web_quantity,
    COALESCE(w.total_web_revenue, 0) AS web_revenue,
    COALESCE(r.avg_rating, NULL) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    (COALESCE(s.total_store_revenue, 0) + COALESCE(w.total_web_revenue, 0)) AS total_revenue,
    (COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0)) AS total_quantity
FROM items i
LEFT JOIN store_item_sales s
    ON i.i_item_id = s.i_item_id
LEFT JOIN web_item_sales w
    ON i.i_item_id = w.i_item_id
LEFT JOIN item_reviews r
    ON i.i_item_id = r.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
