WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name
),
web_item_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
item_reviews AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    s.s_store_name,
    si.i_category_name,
    si.total_store_quantity,
    COALESCE(wi.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ir.review_count, 0) AS review_count,
    ir.avg_rating
FROM store_item_sales si
JOIN stores s
    ON si.ss_store_id = s.s_store_id
LEFT JOIN web_item_sales wi
    ON si.i_category_id = wi.i_category_id
LEFT JOIN item_reviews ir
    ON si.i_category_id = ir.i_category_id
ORDER BY
    s.s_store_name,
    si.i_category_name
