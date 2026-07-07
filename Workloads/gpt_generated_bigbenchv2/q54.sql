WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items i ON ss_item_id = i.i_item_id
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items i ON ws_item_id = i.i_item_id
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    r.avg_sentiment,
    r.review_count
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.pr_item_id
WHERE i.i_price > 0
ORDER BY total_revenue DESC
LIMIT 10
