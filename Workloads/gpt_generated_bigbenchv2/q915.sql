WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(i.i_price * ss.ss_quantity) AS store_revenue
    FROM store_sales ss
    INNER JOIN items i ON ss.ss_item_id = i.i_item_id
    INNER JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    INNER JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(i.i_price * ws.ws_quantity) AS web_revenue
    FROM web_sales ws
    INNER JOIN items i ON ws.ws_item_id = i.i_item_id
    INNER JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    INNER JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id) AS category_id,
    COALESCE(ss.i_category, ws.i_category, r.i_category) AS category,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
    r.avg_sentiment,
    r.review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.i_category_id, ws.i_category_id) = r.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
