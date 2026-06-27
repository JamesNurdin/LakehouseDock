WITH
    rating_agg AS (
        SELECT
            pr.pr_item_id AS item_id,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    sales_agg AS (
        SELECT
            s.item_id,
            SUM(s.quantity) AS total_quantity,
            SUM(s.quantity * s.price) AS total_revenue,
            COUNT(DISTINCT s.customer_id) AS distinct_customers
        FROM (
            SELECT
                ss.ss_item_id AS item_id,
                ss.ss_quantity AS quantity,
                ss.ss_customer_id AS customer_id,
                i.i_price AS price
            FROM store_sales ss
            JOIN items i ON ss.ss_item_id = i.i_item_id

            UNION ALL

            SELECT
                ws.ws_item_id AS item_id,
                ws.ws_quantity AS quantity,
                ws.ws_customer_id AS customer_id,
                i.i_price AS price
            FROM web_sales ws
            JOIN items i ON ws.ws_item_id = i.i_item_id
        ) s
        GROUP BY s.item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.total_quantity, 0) AS total_quantity,
    COALESCE(sa.total_revenue, 0) AS total_revenue,
    COALESCE(sa.distinct_customers, 0) AS distinct_customers,
    ra.avg_rating
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN rating_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_revenue DESC
LIMIT 20
