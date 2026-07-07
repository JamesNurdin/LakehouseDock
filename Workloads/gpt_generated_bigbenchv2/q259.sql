WITH
    item_info AS (
        SELECT
            i_item_id,
            i_category_id,
            i_category,
            i_name,
            i_price
        FROM items
    ),
    store_sales_agg AS (
        SELECT
            ss_item_id AS i_item_id,
            SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id AS i_item_id,
            SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr_item_id AS i_item_id,
            AVG(pr_sentiment) AS avg_sentiment,
            COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    item_combined AS (
        SELECT
            i.i_category_id,
            i.i_category,
            COALESCE(ss.store_quantity, 0) AS store_quantity,
            COALESCE(ws.web_quantity, 0) AS web_quantity,
            r.avg_sentiment,
            COALESCE(r.review_count, 0) AS review_count
        FROM item_info i
        LEFT JOIN store_sales_agg ss ON ss.i_item_id = i.i_item_id
        LEFT JOIN web_sales_agg ws ON ws.i_item_id = i.i_item_id
        LEFT JOIN reviews_agg r ON r.i_item_id = i.i_item_id
    )
SELECT
    i_category_id,
    i_category,
    SUM(store_quantity) AS total_store_quantity,
    SUM(web_quantity) AS total_web_quantity,
    SUM(store_quantity + web_quantity) AS total_quantity,
    AVG(avg_sentiment) AS avg_sentiment_across_items,
    SUM(review_count) AS total_review_count
FROM item_combined
GROUP BY i_category_id, i_category
ORDER BY total_quantity DESC
LIMIT 10
