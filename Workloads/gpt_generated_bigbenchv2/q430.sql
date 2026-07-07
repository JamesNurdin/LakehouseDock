WITH
    store_sales_agg AS (
        SELECT
            i.i_category,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category
    ),
    web_sales_agg AS (
        SELECT
            i.i_category,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i
            ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category
    ),
    reviews_agg AS (
        SELECT
            i.i_category,
            COUNT(pr.pr_review_id) AS review_count,
            AVG(pr.pr_sentiment) AS avg_sentiment
        FROM product_reviews pr
        JOIN items i
            ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category
    )
SELECT
    r.i_category,
    r.review_count,
    r.avg_sentiment,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity_sold,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue
FROM reviews_agg r
LEFT JOIN store_sales_agg s
    ON r.i_category = s.i_category
LEFT JOIN web_sales_agg w
    ON r.i_category = w.i_category
ORDER BY total_revenue DESC
LIMIT 10
