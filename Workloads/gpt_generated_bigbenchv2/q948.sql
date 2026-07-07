WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
combined_sales AS (
    SELECT
        i_category_id,
        i_category,
        item_id,
        quantity,
        i_price,
        customer_id
    FROM store_sales_agg
    UNION ALL
    SELECT
        i_category_id,
        i_category,
        item_id,
        quantity,
        i_price,
        customer_id
    FROM web_sales_agg
),
sales_summary AS (
    SELECT
        cs.i_category_id,
        cs.i_category,
        SUM(cs.quantity) AS total_quantity_sold,
        SUM(cs.quantity * cs.i_price) AS total_revenue,
        COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    GROUP BY cs.i_category_id, cs.i_category
),
review_summary AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_review_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    ss.i_category_id,
    ss.i_category,
    ss.total_quantity_sold,
    ss.total_revenue,
    ss.distinct_customers,
    rs.avg_review_sentiment,
    rs.review_count
FROM sales_summary ss
LEFT JOIN review_summary rs
    ON ss.i_category_id = rs.i_category_id
    AND ss.i_category = rs.i_category
ORDER BY ss.total_revenue DESC
LIMIT 10
