WITH reviews_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_revenue, 0) AS total_revenue
FROM items i
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.pr_item_id
LEFT JOIN sales_agg s
    ON i.i_item_id = s.ss_item_id
WHERE i.i_price > 0
ORDER BY total_quantity DESC
LIMIT 20
