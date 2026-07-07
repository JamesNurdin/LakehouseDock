WITH sentiment_per_item AS (
    SELECT
        pr_item_id AS item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
sales_per_item AS (
    SELECT
        ss_item_id AS item_id,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS sales_count
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT
        ws_item_id AS item_id,
        SUM(ws_quantity) AS total_quantity,
        COUNT(*) AS sales_count
    FROM web_sales
    GROUP BY ws_item_id
),
combined_sales AS (
    SELECT
        item_id,
        SUM(total_quantity) AS total_quantity,
        SUM(sales_count) AS sales_transactions
    FROM sales_per_item
    GROUP BY item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(cs.total_quantity) AS total_quantity_sold,
    AVG(sp.avg_sentiment) AS avg_sentiment,
    SUM(sp.review_count) AS total_reviews
FROM combined_sales cs
JOIN items i
    ON cs.item_id = i.i_item_id
LEFT JOIN sentiment_per_item sp
    ON i.i_item_id = sp.item_id
GROUP BY
    i.i_category_id,
    i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 20
