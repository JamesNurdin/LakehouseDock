WITH
    store_sales_cte AS (
        SELECT
            ss.ss_customer_id AS customer_id,
            ss.ss_item_id AS item_id,
            ss.ss_quantity AS quantity
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    ),
    web_sales_cte AS (
        SELECT
            ws.ws_customer_id AS customer_id,
            ws.ws_item_id AS item_id,
            ws.ws_quantity AS quantity
        FROM web_sales ws
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    ),
    sales_combined AS (
        SELECT customer_id, item_id, quantity FROM store_sales_cte
        UNION ALL
        SELECT customer_id, item_id, quantity FROM web_sales_cte
    ),
    sales_agg AS (
        SELECT
            i.i_category AS category,
            i.i_category_id AS category_id,
            SUM(sc.quantity) AS total_quantity,
            SUM(sc.quantity * i.i_price) AS total_revenue,
            COUNT(DISTINCT sc.customer_id) AS distinct_customers
        FROM sales_combined sc
        JOIN items i ON sc.item_id = i.i_item_id
        GROUP BY i.i_category, i.i_category_id
    ),
    review_agg AS (
        SELECT
            i.i_category AS category,
            i.i_category_id AS category_id,
            AVG(pr.pr_sentiment) AS avg_sentiment,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category, i.i_category_id
    )
SELECT
    s.category,
    s.category_id,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customers,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
LEFT JOIN review_agg r
    ON s.category = r.category
   AND s.category_id = r.category_id
ORDER BY s.total_revenue DESC
LIMIT 10
