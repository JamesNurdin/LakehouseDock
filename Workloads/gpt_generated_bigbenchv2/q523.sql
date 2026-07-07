WITH review_agg AS (
    SELECT
        i.i_item_id,
        COUNT(*) AS review_count,
        SUM(pr.pr_sentiment) AS sentiment_sum
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity
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
item_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        i.i_price,
        COALESCE(r.review_count, 0) AS review_count,
        COALESCE(r.sentiment_sum, 0) AS sentiment_sum,
        COALESCE(s.store_quantity, 0) AS store_quantity,
        COALESCE(w.web_quantity, 0) AS web_quantity
    FROM items i
    LEFT JOIN review_agg r ON r.i_item_id = i.i_item_id
    LEFT JOIN store_sales_agg s ON s.ss_item_id = i.i_item_id
    LEFT JOIN web_sales_agg w ON w.ws_item_id = i.i_item_id
)
SELECT
    i_category_id,
    i_category,
    COUNT(*) AS num_items,
    SUM(review_count) AS total_reviews,
    CASE WHEN SUM(review_count) > 0 THEN SUM(sentiment_sum) / SUM(review_count) ELSE NULL END AS avg_sentiment,
    SUM(store_quantity) AS total_store_quantity,
    SUM(web_quantity) AS total_web_quantity,
    SUM(store_quantity + web_quantity) AS total_quantity_sold,
    AVG(i_price) AS avg_price
FROM item_agg
GROUP BY i_category_id, i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
