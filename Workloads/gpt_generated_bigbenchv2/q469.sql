WITH
    store_item_sales AS (
        SELECT
            store_sales.ss_store_id,
            store_sales.ss_item_id,
            SUM(store_sales.ss_quantity) AS store_quantity,
            SUM(store_sales.ss_quantity * items.i_price) AS store_revenue
        FROM
            store_sales
        JOIN
            items
            ON store_sales.ss_item_id = items.i_item_id
        GROUP BY
            store_sales.ss_store_id,
            store_sales.ss_item_id
    ),
    web_item_sales AS (
        SELECT
            web_sales.ws_item_id,
            SUM(web_sales.ws_quantity) AS web_quantity,
            SUM(web_sales.ws_quantity * items.i_price) AS web_revenue
        FROM
            web_sales
        JOIN
            items
            ON web_sales.ws_item_id = items.i_item_id
        GROUP BY
            web_sales.ws_item_id
    ),
    item_ratings AS (
        SELECT
            items.i_item_id,
            AVG(product_reviews.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM
            product_reviews
        JOIN
            items
            ON product_reviews.pr_item_id = items.i_item_id
        GROUP BY
            items.i_item_id
    ),
    store_customer_counts AS (
        SELECT
            store_sales.ss_store_id,
            COUNT(DISTINCT store_sales.ss_customer_id) AS unique_customers
        FROM
            store_sales
        GROUP BY
            store_sales.ss_store_id
    )
SELECT
    s.s_store_name,
    s.s_store_id,
    sc.unique_customers,
    i.i_item_id,
    i.i_name,
    ss.store_quantity,
    ss.store_revenue,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ws.web_revenue, 0) AS web_revenue,
    ss.store_quantity + COALESCE(ws.web_quantity, 0) AS total_quantity,
    ss.store_revenue + COALESCE(ws.web_revenue, 0) AS total_revenue,
    ir.avg_rating,
    ir.review_count
FROM
    store_item_sales ss
JOIN
    stores s
    ON ss.ss_store_id = s.s_store_id
JOIN
    items i
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN
    web_item_sales ws
    ON ss.ss_item_id = ws.ws_item_id
LEFT JOIN
    item_ratings ir
    ON ss.ss_item_id = ir.i_item_id
LEFT JOIN
    store_customer_counts sc
    ON ss.ss_store_id = sc.ss_store_id
ORDER BY
    s.s_store_name,
    i.i_name
