WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_revenue
    FROM items i
    JOIN store_sales ss
        ON i.i_item_id = ss.ss_item_id
    GROUP BY i.i_category, i.i_category_id
),
reviews_agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM items i
    JOIN product_reviews pr
        ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT
    s.i_category,
    s.i_category_id,
    s.total_quantity,
    s.total_revenue,
    r.review_count,
    r.avg_sentiment
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.i_category_id = r.i_category_id
    AND s.i_category = r.i_category
ORDER BY s.total_revenue DESC
LIMIT 10
