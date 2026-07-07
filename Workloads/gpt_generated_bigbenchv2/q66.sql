WITH review_stats AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
sales_store AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
sales_web AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        COALESCE(s.store_qty, 0) AS store_qty,
        COALESCE(w.web_qty, 0) AS web_qty,
        COALESCE(r.review_count, 0) AS review_count,
        r.avg_sentiment
    FROM items i
    LEFT JOIN sales_store s ON s.ss_item_id = i.i_item_id
    LEFT JOIN sales_web w ON w.ws_item_id = i.i_item_id
    LEFT JOIN review_stats r ON r.pr_item_id = i.i_item_id
    WHERE COALESCE(r.review_count, 0) >= 10
)
SELECT
    i_category_id,
    i_category,
    SUM(store_qty + web_qty) AS total_quantity_sold,
    AVG(avg_sentiment) AS category_avg_sentiment,
    COUNT(*) AS num_items
FROM item_sales
GROUP BY i_category_id, i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
