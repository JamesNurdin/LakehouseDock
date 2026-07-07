WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_store_qty,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_web_qty,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COALESCE(SUM(sa.total_store_qty), 0) + COALESCE(SUM(wa.total_web_qty), 0) AS total_quantity_sold,
    COALESCE(SUM(sa.total_store_revenue), 0) + COALESCE(SUM(wa.total_web_revenue), 0) AS total_revenue,
    COALESCE(SUM(r.review_count), 0) AS total_reviews,
    AVG(r.avg_sentiment) AS avg_sentiment_per_item
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
