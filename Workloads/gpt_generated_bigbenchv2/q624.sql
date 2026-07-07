WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS category_id,
    COALESCE(s.i_category, w.i_category, r.i_category) AS category_name,
    COALESCE(s.store_quantity, 0) AS total_store_quantity,
    COALESCE(s.store_revenue, 0) AS total_store_revenue,
    COALESCE(w.web_quantity, 0) AS total_web_quantity,
    COALESCE(w.web_revenue, 0) AS total_web_revenue,
    r.avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.i_category_id = w.i_category_id
FULL OUTER JOIN review_agg r ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
ORDER BY (COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0)) DESC
LIMIT 10
