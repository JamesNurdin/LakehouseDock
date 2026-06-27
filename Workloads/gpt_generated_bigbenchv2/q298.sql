WITH
    -- Aggregate sales per store‑item (including revenue)
    store_item_sales AS (
        SELECT
            ss.ss_store_id,
            ss.ss_item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_store_id, ss.ss_item_id
    ),
    -- Average rating per item (from product reviews)
    item_ratings AS (
        SELECT
            pr.pr_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS rating_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    -- Store‑level weighted average rating and overall sales metrics
    store_rating AS (
        SELECT
            si.ss_store_id,
            SUM(si.store_quantity * COALESCE(ir.avg_rating, 0)) / NULLIF(SUM(si.store_quantity), 0) AS weighted_avg_rating,
            SUM(si.store_quantity) AS total_quantity,
            SUM(si.store_revenue) AS total_revenue
        FROM store_item_sales si
        LEFT JOIN item_ratings ir ON si.ss_item_id = ir.pr_item_id
        GROUP BY si.ss_store_id
    ),
    -- Sales per store‑customer (including revenue)
    store_customer_sales AS (
        SELECT
            ss.ss_store_id,
            ss.ss_customer_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_store_id, ss.ss_customer_id
    ),
    -- Web sales per customer (including revenue)
    web_customer_sales AS (
        SELECT
            ws.ws_customer_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_customer_id
    ),
    -- Combine store‑customer sales with the same customers' web sales
    store_web_agg AS (
        SELECT
            scs.ss_store_id,
            SUM(wcs.web_quantity) AS total_web_quantity,
            SUM(wcs.web_revenue) AS total_web_revenue,
            COUNT(DISTINCT scs.ss_customer_id) AS distinct_customers
        FROM store_customer_sales scs
        JOIN customers c ON scs.ss_customer_id = c.c_customer_id
        JOIN web_customer_sales wcs ON c.c_customer_id = wcs.ws_customer_id
        GROUP BY scs.ss_store_id
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    sr.total_quantity,
    sr.total_revenue,
    sr.weighted_avg_rating,
    sw.total_web_quantity,
    sw.total_web_revenue,
    sw.distinct_customers
FROM stores s
JOIN store_rating sr ON s.s_store_id = sr.ss_store_id
LEFT JOIN store_web_agg sw ON s.s_store_id = sw.ss_store_id
ORDER BY sr.total_revenue DESC
LIMIT 20
