WITH store_qty AS (
    SELECT
        ss_item_id AS item_id,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_qty AS (
    SELECT
        ws_item_id AS item_id,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_qty AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_category_id,
        COALESCE(sq.store_quantity, 0) + COALESCE(wq.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_qty sq ON i.i_item_id = sq.item_id
    LEFT JOIN web_qty wq ON i.i_item_id = wq.item_id
),
item_sentiment AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    iq.i_category,
    iq.i_category_id,
    SUM(iq.total_quantity) AS total_quantity_sold,
    AVG(COALESCE(its.avg_sentiment, 0)) AS avg_review_sentiment,
    COUNT(DISTINCT iq.i_item_id) AS distinct_items_sold
FROM item_qty iq
LEFT JOIN item_sentiment its ON iq.i_item_id = its.item_id
GROUP BY iq.i_category, iq.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
