WITH review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    AVG(r.avg_sentiment) AS category_avg_sentiment,
    SUM(s.total_quantity_sold) AS category_total_quantity_sold,
    SUM(r.review_count) AS category_review_count,
    SUM(s.distinct_customers) AS category_distinct_customers
FROM items i
JOIN review_agg r ON i.i_item_id = r.item_id
JOIN sales_agg s ON i.i_item_id = s.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY category_avg_sentiment DESC
