WITH store_agg AS (
    SELECT
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id
),
web_agg AS (
    SELECT
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id
),
sales_agg AS (
    SELECT
        COALESCE(sa.category, wa.category) AS category,
        COALESCE(sa.item_id, wa.item_id) AS item_id,
        COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
        COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
        COALESCE(sa.store_customers, 0) + COALESCE(wa.web_customers, 0) AS total_customers
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa ON sa.item_id = wa.item_id
),
review_agg AS (
    SELECT
        i.i_category AS category,
        i.i_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id
)
SELECT
    s.category,
    SUM(s.total_quantity) AS total_quantity_sold,
    SUM(s.total_revenue) AS total_revenue,
    COUNT(DISTINCT s.item_id) AS distinct_items_sold,
    SUM(s.total_customers) AS total_customers,
    AVG(r.avg_sentiment) AS avg_review_sentiment,
    SUM(r.review_count) AS total_reviews
FROM sales_agg s
LEFT JOIN review_agg r ON s.item_id = r.item_id
GROUP BY s.category
ORDER BY total_revenue DESC
LIMIT 10
