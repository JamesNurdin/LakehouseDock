WITH
    store_sales_agg AS (
        SELECT
            ss.ss_item_id AS i_item_id,
            SUM(ss.ss_quantity) AS store_qty,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customers
        FROM store_sales ss
        GROUP BY ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id AS i_item_id,
            SUM(ws.ws_quantity) AS web_qty,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customers
        FROM web_sales ws
        GROUP BY ws.ws_item_id
    ),
    rating_agg AS (
        SELECT
            pr.pr_item_id AS i_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    i.i_category_name,
    SUM(COALESCE(sa.store_qty, 0)) AS total_store_quantity,
    SUM(COALESCE(wa.web_qty, 0)) AS total_web_quantity,
    SUM(COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) AS total_quantity,
    SUM((COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) * i.i_price) AS total_revenue,
    AVG(r.avg_rating) AS avg_item_rating,
    SUM(COALESCE(sa.store_customers, 0) + COALESCE(wa.web_customers, 0)) AS total_customer_counts
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN rating_agg r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
