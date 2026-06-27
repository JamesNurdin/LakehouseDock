WITH
    store_sales_agg AS (
        SELECT
            ss.ss_item_id AS item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id AS item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i
            ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr.pr_item_id AS item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    customer_counts AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_customers
        FROM (
            SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id
            FROM store_sales ss
            UNION ALL
            SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id
            FROM web_sales ws
        ) AS combined
        GROUP BY item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity_sold,
    COALESCE(ssa.store_revenue, 0) + COALESCE(wsa.web_revenue, 0) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    cc.distinct_customers
FROM items i
LEFT JOIN store_sales_agg ssa
    ON i.i_item_id = ssa.item_id
LEFT JOIN web_sales_agg wsa
    ON i.i_item_id = wsa.item_id
LEFT JOIN reviews_agg ra
    ON i.i_item_id = ra.item_id
LEFT JOIN customer_counts cc
    ON i.i_item_id = cc.item_id
ORDER BY total_revenue DESC
LIMIT 10
