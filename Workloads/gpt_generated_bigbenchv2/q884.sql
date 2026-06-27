WITH
    -- Aggregate store‑sales per store and category
    store_sales_agg AS (
        SELECT
            ss.ss_store_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_store_id, i.i_category_name
    )
SELECT
    s.s_store_name,
    agg.i_category_name,
    agg.store_quantity,
    COALESCE(
        (
            SELECT SUM(ws.ws_quantity)
            FROM web_sales ws
            JOIN items i2 ON ws.ws_item_id = i2.i_item_id
            WHERE i2.i_category_name = agg.i_category_name
        ),
        0
    ) AS web_quantity,
    (
        SELECT SUM(ws.ws_quantity)
        FROM web_sales ws
        JOIN items i2 ON ws.ws_item_id = i2.i_item_id
        WHERE i2.i_category_name = agg.i_category_name
    ) + agg.store_quantity AS total_quantity,
    COALESCE(
        (
            SELECT AVG(pr.pr_rating)
            FROM product_reviews pr
            JOIN items i3 ON pr.pr_item_id = i3.i_item_id
            WHERE i3.i_category_name = agg.i_category_name
        ),
        0
    ) AS avg_rating,
    COALESCE(
        (
            SELECT AVG(i4.i_price)
            FROM items i4
            WHERE i4.i_category_name = agg.i_category_name
        ),
        0
    ) AS avg_price
FROM store_sales_agg agg
JOIN stores s ON agg.ss_store_id = s.s_store_id
ORDER BY total_quantity DESC, s.s_store_name, agg.i_category_name
