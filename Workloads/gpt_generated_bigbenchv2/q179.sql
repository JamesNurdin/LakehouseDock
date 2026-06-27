WITH
    store_sales_by_category_store AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            s.s_store_id,
            s.s_store_name,
            SUM(ss.ss_quantity) AS total_store_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_category_id, i.i_category_name, s.s_store_id, s.s_store_name
    ),
    web_sales_by_category AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_web_quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    product_reviews_by_category AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    items_price_by_category AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(i.i_price) AS avg_price
        FROM items i
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT
    ss.i_category_id,
    ss.i_category_name,
    ss.s_store_id,
    ss.s_store_name,
    ss.total_store_quantity,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(pr.avg_rating, 0) AS avg_rating,
    COALESCE(pr.review_count, 0) AS review_count,
    ip.avg_price,
    (ss.total_store_quantity + COALESCE(ws.total_web_quantity, 0)) AS total_quantity,
    (ss.total_store_quantity + COALESCE(ws.total_web_quantity, 0)) * ip.avg_price AS total_revenue
FROM store_sales_by_category_store ss
LEFT JOIN web_sales_by_category ws
    ON ss.i_category_id = ws.i_category_id
LEFT JOIN product_reviews_by_category pr
    ON ss.i_category_id = pr.i_category_id
LEFT JOIN items_price_by_category ip
    ON ss.i_category_id = ip.i_category_id
ORDER BY total_revenue DESC
LIMIT 100
