WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_customer_id) AS store_customer_cnt
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws_customer_id) AS web_customer_cnt
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(ss.store_quantity, 0) AS total_store_quantity,
    COALESCE(ws.web_quantity, 0) AS total_web_quantity,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_customer_cnt, 0) + COALESCE(ws.web_customer_cnt, 0) AS total_customer_cnt,
    COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(r.review_cnt, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 100
