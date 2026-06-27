WITH
    item_rating AS (
        SELECT
            i.i_item_id,
            AVG(pr.pr_rating) AS avg_rating
        FROM items i
        LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    store_sales_data AS (
        SELECT
            ss.ss_customer_id,
            i.i_item_id,
            i.i_category_name,
            ss.ss_quantity,
            ss.ss_quantity * i.i_price AS revenue,
            ir.avg_rating
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        LEFT JOIN item_rating ir ON i.i_item_id = ir.i_item_id
    ),
    web_sales_data AS (
        SELECT
            ws.ws_customer_id,
            i.i_item_id,
            i.i_category_name,
            ws.ws_quantity,
            ws.ws_quantity * i.i_price AS revenue,
            ir.avg_rating
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        LEFT JOIN item_rating ir ON i.i_item_id = ir.i_item_id
    ),
    combined_sales AS (
        SELECT
            i_category_name,
            'store' AS channel,
            ss_quantity AS quantity,
            revenue,
            ss_customer_id AS customer_id,
            avg_rating
        FROM store_sales_data
        UNION ALL
        SELECT
            i_category_name,
            'web' AS channel,
            ws_quantity AS quantity,
            revenue,
            ws_customer_id AS customer_id,
            avg_rating
        FROM web_sales_data
    )
SELECT
    cs.i_category_name AS category_name,
    cs.channel,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.revenue) AS total_revenue,
    COUNT(DISTINCT cs.customer_id) AS distinct_customer_count,
    AVG(cs.avg_rating) AS average_item_rating
FROM combined_sales cs
GROUP BY cs.i_category_name, cs.channel
ORDER BY total_revenue DESC
