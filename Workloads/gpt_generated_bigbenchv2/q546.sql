WITH sales_raw AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),

sales_agg AS (
    SELECT
        sr.item_id,
        SUM(sr.quantity) AS total_quantity,
        COUNT(DISTINCT sr.customer_id) AS distinct_customers
    FROM sales_raw sr
    GROUP BY sr.item_id
),

review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    i.i_name AS item_name,
    i.i_price AS price,
    i.i_comp_price AS competitor_price,
    sa.total_quantity,
    sa.distinct_customers,
    COALESCE(ra.avg_sentiment, NULL) AS avg_review_sentiment,
    COALESCE(ra.review_count, 0) AS review_count
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON sa.item_id = ra.item_id
WHERE i.i_price > 10
ORDER BY sa.total_quantity DESC
LIMIT 20
