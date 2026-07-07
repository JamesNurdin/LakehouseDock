WITH store_sales_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_unique_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores st ON ss.ss_store_id = st.s_store_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_unique_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(s.category_id, w.category_id, r.category_id) AS category_id,
    COALESCE(s.category, w.category, r.category) AS category,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
    COALESCE(s.store_unique_customers, 0) + COALESCE(w.web_unique_customers, 0) AS total_unique_customers,
    r.avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.category_id = w.category_id
FULL OUTER JOIN reviews_agg r ON COALESCE(s.category_id, w.category_id) = r.category_id
ORDER BY total_revenue DESC
LIMIT 20
