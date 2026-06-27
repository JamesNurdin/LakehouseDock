WITH
    item_online_sales AS (
        SELECT
            ws_item_id AS i_item_id,
            SUM(ws_quantity) AS total_online_qty
        FROM web_sales
        GROUP BY ws_item_id
    ),
    store_items AS (
        SELECT DISTINCT
            ss_store_id AS s_store_id,
            ss_item_id AS i_item_id
        FROM store_sales
    ),
    store_instore_sales AS (
        SELECT
            ss_store_id AS s_store_id,
            SUM(ss_quantity) AS total_instore_qty
        FROM store_sales
        GROUP BY ss_store_id
    ),
    store_online_sales AS (
        SELECT
            si.s_store_id,
            SUM(COALESCE(ios.total_online_qty, 0)) AS total_online_qty
        FROM store_items si
        JOIN items i
            ON si.i_item_id = i.i_item_id
        LEFT JOIN item_online_sales ios
            ON i.i_item_id = ios.i_item_id
        GROUP BY si.s_store_id
    ),
    item_reviews_agg AS (
        SELECT
            pr_item_id AS i_item_id,
            AVG(pr_rating) AS avg_rating
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    store_item_aggregates AS (
        SELECT
            si.s_store_id,
            AVG(i.i_price) AS avg_item_price,
            AVG(ir.avg_rating) AS avg_item_rating
        FROM store_items si
        JOIN items i
            ON si.i_item_id = i.i_item_id
        LEFT JOIN item_reviews_agg ir
            ON i.i_item_id = ir.i_item_id
        GROUP BY si.s_store_id
    )
SELECT
    s.s_store_name,
    COALESCE(ins.total_instore_qty, 0) AS total_instore_quantity,
    COALESCE(onl.total_online_qty, 0) AS total_online_quantity,
    COALESCE(agg.avg_item_price, 0) AS avg_item_price,
    COALESCE(agg.avg_item_rating, 0) AS avg_item_rating,
    (COALESCE(onl.total_online_qty, 0) * 1.0) /
        NULLIF(COALESCE(ins.total_instore_qty, 0) + COALESCE(onl.total_online_qty, 0), 0) AS online_to_total_ratio
FROM stores s
LEFT JOIN store_instore_sales ins
    ON s.s_store_id = ins.s_store_id
LEFT JOIN store_online_sales onl
    ON s.s_store_id = onl.s_store_id
LEFT JOIN store_item_aggregates agg
    ON s.s_store_id = agg.s_store_id
ORDER BY total_instore_quantity DESC
LIMIT 10
