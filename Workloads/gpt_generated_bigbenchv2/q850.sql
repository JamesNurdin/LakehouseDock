WITH
    store_sales_agg AS (
        SELECT
            ss.ss_item_id AS item_id,
            ss.ss_store_id AS store_id,
            SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        GROUP BY ss.ss_item_id, ss.ss_store_id
    ),
    top_store_rank AS (
        SELECT
            ssa.item_id,
            ssa.store_id,
            ssa.store_quantity,
            ROW_NUMBER() OVER (PARTITION BY ssa.item_id ORDER BY ssa.store_quantity DESC) AS rn
        FROM store_sales_agg ssa
    ),
    top_store AS (
        SELECT
            tsr.item_id,
            tsr.store_id,
            tsr.store_quantity
        FROM top_store_rank tsr
        WHERE tsr.rn = 1
    ),
    total_sales AS (
        SELECT
            item_id,
            SUM(quantity) AS total_quantity
        FROM (
            SELECT ss.ss_item_id AS item_id, ss.ss_quantity AS quantity FROM store_sales ss
            UNION ALL
            SELECT ws.ws_item_id AS item_id, ws.ws_quantity AS quantity FROM web_sales ws
        ) AS all_sales
        GROUP BY item_id
    ),
    distinct_customers AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_customer_count
        FROM (
            SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id FROM store_sales ss
            UNION ALL
            SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id FROM web_sales ws
        ) AS cust_sales
        GROUP BY item_id
    ),
    item_ratings AS (
        SELECT
            pr.pr_item_id AS item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    i.i_item_id AS item_id,
    i.i_name AS item_name,
    i.i_category_name AS category_name,
    i.i_price AS price,
    ts.total_quantity,
    dc.distinct_customer_count,
    ir.avg_rating,
    ir.review_count,
    s.s_store_name AS top_store_name,
    tsr.store_quantity AS top_store_quantity,
    i.i_price * ts.total_quantity AS total_revenue
FROM items i
LEFT JOIN total_sales ts ON i.i_item_id = ts.item_id
LEFT JOIN distinct_customers dc ON i.i_item_id = dc.item_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.item_id
LEFT JOIN top_store tsr ON i.i_item_id = tsr.item_id
LEFT JOIN stores s ON tsr.store_id = s.s_store_id
WHERE ts.total_quantity IS NOT NULL
ORDER BY i.i_price * ts.total_quantity DESC
LIMIT 10
