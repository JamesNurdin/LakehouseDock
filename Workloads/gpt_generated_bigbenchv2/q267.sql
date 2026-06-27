WITH offline_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS offline_quantity,
        SUM(ss.ss_quantity * i.i_price) AS offline_sales_amount
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
online_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS online_quantity,
        SUM(ws.ws_quantity * i.i_price) AS online_sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_ratings AS (
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
    o.s_store_id,
    o.s_store_name,
    o.i_category_id,
    o.i_category_name,
    o.offline_quantity,
    o.offline_sales_amount,
    COALESCE(onl.online_quantity, 0) AS online_quantity,
    COALESCE(onl.online_sales_amount, 0) AS online_sales_amount,
    cr.avg_rating,
    cr.review_count
FROM offline_sales o
LEFT JOIN online_sales onl
    ON o.i_category_id = onl.i_category_id
LEFT JOIN category_ratings cr
    ON o.i_category_id = cr.i_category_id
ORDER BY o.s_store_name, o.i_category_name
