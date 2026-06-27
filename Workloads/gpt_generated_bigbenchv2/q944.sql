WITH
    store_agg AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_name,
            s.s_store_id,
            s.s_store_name,
            SUM(ss.ss_quantity) AS total_store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_name, s.s_store_id, s.s_store_name
    ),
    web_agg AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_name
    ),
    review_agg AS (
        SELECT
            i.i_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    )
SELECT
    s.i_item_id,
    s.i_name,
    s.i_category_name,
    s.s_store_id,
    s.s_store_name,
    s.total_store_quantity,
    s.total_store_revenue,
    COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(w.total_web_revenue, 0) AS total_web_revenue,
    r.avg_rating,
    r.review_count,
    (s.total_store_quantity + COALESCE(w.total_web_quantity, 0)) AS total_quantity_all_channels,
    (s.total_store_revenue + COALESCE(w.total_web_revenue, 0)) AS total_revenue_all_channels
FROM store_agg s
LEFT JOIN web_agg w ON s.i_item_id = w.i_item_id
LEFT JOIN review_agg r ON s.i_item_id = r.i_item_id
WHERE r.avg_rating >= 4
ORDER BY total_revenue_all_channels DESC
LIMIT 20
