WITH
store_sales_agg AS (
    SELECT
        ss_item_id AS item_id,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id AS item_id,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT
        pr_item_id AS item_id,
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
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    r.avg_sentiment,
    r.review_count
FROM items i
LEFT JOIN store_sales_agg s
    ON i.i_item_id = s.item_id
LEFT JOIN web_sales_agg w
    ON i.i_item_id = w.item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.item_id
WHERE COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) > 0
ORDER BY total_quantity DESC
LIMIT 10
