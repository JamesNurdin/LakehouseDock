WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_customer_id AS customer_id,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ws.ws_customer_id AS customer_id,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT i_category_id, i_category_name, customer_id, quantity FROM store_sales_agg
    UNION ALL
    SELECT i_category_id, i_category_name, customer_id, quantity FROM web_sales_agg
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cs.i_category_id,
    cs.i_category_name,
    SUM(cs.quantity) AS total_quantity,
    COUNT(DISTINCT cs.customer_id) AS distinct_customer_count,
    ra.avg_rating,
    ra.review_count
FROM combined_sales cs
LEFT JOIN review_agg ra
    ON cs.i_category_id = ra.i_category_id
GROUP BY cs.i_category_id, cs.i_category_name, ra.avg_rating, ra.review_count
ORDER BY total_quantity DESC
LIMIT 10
