WITH avg_category_rating AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_sales_enriched AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_enriched AS (
    SELECT
        NULL AS ss_store_id,
        'Online' AS s_store_name,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
)
SELECT
    COALESCE(cs.ss_store_id, -1) AS store_id,
    cs.s_store_name AS store_name,
    cs.i_category_id AS category_id,
    cs.i_category_name AS category_name,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.revenue) AS total_revenue,
    COUNT(DISTINCT cs.customer_id) AS distinct_customers,
    cr.avg_rating
FROM combined_sales cs
LEFT JOIN avg_category_rating cr
    ON cs.i_category_id = cr.i_category_id
GROUP BY
    cs.ss_store_id,
    cs.s_store_name,
    cs.i_category_id,
    cs.i_category_name,
    cr.avg_rating
ORDER BY total_revenue DESC
LIMIT 20
