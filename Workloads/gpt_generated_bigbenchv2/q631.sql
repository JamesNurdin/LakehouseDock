WITH sales_union AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT
        s.item_id,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * i.i_price) AS total_revenue
    FROM sales_union s
    JOIN items i
        ON s.item_id = i.i_item_id
    GROUP BY s.item_id
),
item_reviews AS (
    SELECT
        pr.pr_item_id AS item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    isales.total_quantity,
    isales.total_revenue,
    COALESCE(irev.review_count, 0) AS review_count,
    COALESCE(irev.avg_sentiment, 0) AS avg_sentiment
FROM item_sales isales
JOIN items i
    ON isales.item_id = i.i_item_id
LEFT JOIN item_reviews irev
    ON i.i_item_id = irev.item_id
ORDER BY isales.total_revenue DESC
LIMIT 10
