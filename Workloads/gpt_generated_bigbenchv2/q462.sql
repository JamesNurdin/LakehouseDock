WITH store_sales_agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
web_sales_agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
reviews_agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT
    COALESCE(ss.i_category, ws.i_category, r.i_category) AS category,
    COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id) AS category_id,
    COALESCE(ss.total_quantity, 0) + COALESCE(ws.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.total_revenue, 0) + COALESCE(ws.total_revenue, 0) AS total_revenue,
    COALESCE(ss.distinct_customers, 0) + COALESCE(ws.distinct_customers, 0) AS distinct_customers,
    r.avg_sentiment,
    r.review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category = ws.i_category
    AND ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.i_category, ws.i_category) = r.i_category
    AND COALESCE(ss.i_category_id, ws.i_category_id) = r.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
