WITH sales AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales_total AS (
    SELECT
        COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
        COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
        COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue
    FROM sales s
    FULL OUTER JOIN web_sales_agg w ON s.i_item_id = w.i_item_id
),
review_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(st.total_quantity) AS total_quantity_sold,
    SUM(st.total_revenue) AS total_revenue,
    AVG(r.avg_sentiment) AS avg_review_sentiment,
    SUM(r.review_count) AS total_reviews
FROM sales_total st
JOIN items i ON st.i_item_id = i.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
