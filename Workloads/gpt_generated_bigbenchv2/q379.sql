WITH sales_by_category AS (
    SELECT
        i.i_category AS category,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
sentiment_by_category AS (
    SELECT
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.category,
    s.total_revenue,
    s.distinct_customers,
    p.avg_sentiment
FROM sales_by_category s
LEFT JOIN sentiment_by_category p
    ON s.category = p.category
ORDER BY s.total_revenue DESC
