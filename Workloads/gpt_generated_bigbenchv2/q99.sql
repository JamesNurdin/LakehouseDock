WITH store_sales_by_store_category AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    ssbc.i_category_name,
    ssbc.store_quantity,
    COALESCE(
        (
            SELECT SUM(ws.ws_quantity)
            FROM web_sales ws
            JOIN items i2 ON ws.ws_item_id = i2.i_item_id
            WHERE i2.i_category_id = ssbc.i_category_id
        ),
        0
    ) AS web_quantity,
    ssbc.store_quantity + COALESCE(
        (
            SELECT SUM(ws.ws_quantity)
            FROM web_sales ws
            JOIN items i2 ON ws.ws_item_id = i2.i_item_id
            WHERE i2.i_category_id = ssbc.i_category_id
        ),
        0
    ) AS total_quantity,
    (
        SELECT AVG(pr.pr_rating)
        FROM product_reviews pr
        JOIN items i3 ON pr.pr_item_id = i3.i_item_id
        WHERE i3.i_category_id = ssbc.i_category_id
    ) AS avg_category_rating,
    (
        SELECT COUNT(*)
        FROM product_reviews pr
        JOIN items i3 ON pr.pr_item_id = i3.i_item_id
        WHERE i3.i_category_id = ssbc.i_category_id
    ) AS review_count
FROM store_sales_by_store_category ssbc
JOIN stores s ON s.s_store_id = ssbc.ss_store_id
WHERE (
    SELECT COUNT(*)
    FROM product_reviews pr
    JOIN items i3 ON pr.pr_item_id = i3.i_item_id
    WHERE i3.i_category_id = ssbc.i_category_id
) >= 5
ORDER BY total_quantity DESC
LIMIT 10
