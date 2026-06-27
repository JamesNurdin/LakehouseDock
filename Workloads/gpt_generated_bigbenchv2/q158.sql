WITH
    -- Aggregate store‑level sales per item and store (price comes from items)
    store_sales_agg AS (
        SELECT
            ss.ss_item_id AS item_id,
            ss.ss_store_id AS store_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id, ss.ss_store_id
    ),
    -- Rank stores for each item by revenue to pick the top‑selling store
    store_rank AS (
        SELECT
            s.item_id,
            s.store_id,
            s.store_quantity,
            s.store_revenue,
            ROW_NUMBER() OVER (PARTITION BY s.item_id ORDER BY s.store_revenue DESC) AS rn
        FROM store_sales_agg s
    ),
    top_store_per_item AS (
        SELECT
            sr.item_id,
            sr.store_id,
            sr.store_quantity,
            sr.store_revenue
        FROM store_rank sr
        WHERE sr.rn = 1
    ),
    -- Store sales with price and revenue per transaction
    store_sales_combined AS (
        SELECT
            ss.ss_item_id AS item_id,
            ss.ss_quantity AS quantity,
            ss.ss_quantity * i.i_price AS revenue,
            ss.ss_customer_id AS customer_id,
            ss.ss_store_id AS store_id
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
    ),
    -- Web sales with price and revenue per transaction (no store_id)
    web_sales_combined AS (
        SELECT
            ws.ws_item_id AS item_id,
            ws.ws_quantity AS quantity,
            ws.ws_quantity * i.i_price AS revenue,
            ws.ws_customer_id AS customer_id,
            NULL AS store_id
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    -- Union of all sales channels
    all_sales AS (
        SELECT * FROM store_sales_combined
        UNION ALL
        SELECT * FROM web_sales_combined
    ),
    -- Item‑level metrics across all channels
    item_metrics AS (
        SELECT
            a.item_id,
            SUM(a.quantity) AS total_quantity,
            SUM(a.revenue) AS total_revenue,
            COUNT(DISTINCT a.customer_id) AS distinct_customers
        FROM all_sales a
        GROUP BY a.item_id
    ),
    -- Average rating and review count per item
    item_ratings AS (
        SELECT
            pr.pr_item_id AS item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    im.total_quantity,
    im.total_revenue,
    im.distinct_customers,
    ir.avg_rating,
    ir.review_count,
    s.s_store_name AS top_store_name,
    tsp.store_quantity AS top_store_quantity,
    tsp.store_revenue AS top_store_revenue
FROM item_metrics im
JOIN items i ON im.item_id = i.i_item_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.item_id
LEFT JOIN top_store_per_item tsp ON i.i_item_id = tsp.item_id
LEFT JOIN stores s ON tsp.store_id = s.s_store_id
ORDER BY im.total_revenue DESC
LIMIT 10
