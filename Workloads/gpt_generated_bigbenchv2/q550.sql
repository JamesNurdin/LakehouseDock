WITH
    store_sales_agg AS (
        SELECT
            ss.ss_item_id AS item_id,
            COUNT(DISTINCT ss.ss_store_id) AS num_stores,
            SUM(ss.ss_quantity) AS total_store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id AS item_id,
            SUM(ws.ws_quantity) AS total_web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr.pr_item_id AS item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS num_reviews
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS num_items,
    COALESCE(SUM(ssa.num_stores), 0) AS total_num_stores,
    COALESCE(SUM(ssa.total_store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(ssa.total_store_revenue), 0) AS total_store_revenue,
    COALESCE(SUM(wsa.total_web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(wsa.total_web_revenue), 0) AS total_web_revenue,
    COALESCE(AVG(r.avg_rating), 0) AS avg_rating,
    COALESCE(SUM(r.num_reviews), 0) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_store_revenue DESC
LIMIT 10
