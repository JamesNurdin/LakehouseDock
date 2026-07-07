WITH sales_agg AS (
    SELECT
        item_id,
        SUM(quantity) AS total_quantity
    FROM (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity FROM web_sales
    ) s
    GROUP BY item_id
),
review_agg AS (
    SELECT
        pr_item_id AS item_id,
        COUNT(*) AS review_count,
        AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_sentiment,
    (COALESCE(s.total_quantity, 0) * i.i_price) AS total_revenue
FROM items i
LEFT JOIN sales_agg s ON s.item_id = i.i_item_id
LEFT JOIN review_agg r ON r.item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
