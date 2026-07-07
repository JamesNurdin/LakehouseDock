WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(*) AS store_transactions
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(*) AS web_transactions
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        i.i_price,
        COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
        (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) * i.i_price AS total_revenue
    FROM items i
    LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
    LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
    WHERE i.i_category = 'Electronics'
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    isales.i_item_id,
    isales.i_name,
    isales.i_category,
    isales.total_quantity,
    isales.total_revenue,
    COALESCE(reviews.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(reviews.review_count, 0) AS review_count
FROM item_sales isales
LEFT JOIN item_reviews reviews ON reviews.pr_item_id = isales.i_item_id
ORDER BY isales.total_revenue DESC
LIMIT 10
