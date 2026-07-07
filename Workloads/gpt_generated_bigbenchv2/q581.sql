WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_store_id) AS distinct_store_count
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
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
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity_sold,
    (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) * i.i_price AS total_revenue,
    r.avg_sentiment,
    ss.distinct_store_count
FROM items i
LEFT JOIN store_sales_agg ss
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws
    ON ws.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r
    ON r.pr_item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
