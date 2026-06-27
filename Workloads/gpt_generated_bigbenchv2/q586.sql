WITH
    -- Aggregate store sales per item (quantity and revenue)
    store_agg AS (
        SELECT
            ss.ss_item_id AS item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id
    ),
    -- Aggregate web sales per item (quantity and revenue)
    web_agg AS (
        SELECT
            ws.ws_item_id AS item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    -- Average rating and count of reviews per item
    ratings AS (
        SELECT
            pr.pr_item_id AS item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS rating_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    -- Customers who bought each item in stores (joined to customers per rule)
    store_cust AS (
        SELECT
            ss.ss_item_id AS item_id,
            ss.ss_customer_id AS customer_id
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    ),
    -- Customers who bought each item online (joined to customers per rule)
    web_cust AS (
        SELECT
            ws.ws_item_id AS item_id,
            ws.ws_customer_id AS customer_id
        FROM web_sales ws
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    ),
    -- Distinct number of customers per item across both channels
    item_customers AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_customer_count
        FROM (
            SELECT item_id, customer_id FROM store_cust
            UNION ALL
            SELECT item_id, customer_id FROM web_cust
        ) AS combined
        GROUP BY item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    r.avg_rating,
    r.rating_count,
    COALESCE(ic.distinct_customer_count, 0) AS distinct_customer_count
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN ratings r ON i.i_item_id = r.item_id
LEFT JOIN item_customers ic ON i.i_item_id = ic.item_id
ORDER BY total_revenue DESC
LIMIT 10
