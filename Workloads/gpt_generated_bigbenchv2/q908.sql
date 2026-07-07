WITH sales_reviews AS (
    SELECT
        s.s_store_name AS s_store_name,
        i.i_category AS i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        COUNT(pr.pr_review_id) AS review_count
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY s.s_store_name, i.i_category
)
SELECT
    s_store_name,
    i_category,
    total_quantity,
    avg_sentiment,
    distinct_customers,
    review_count
FROM sales_reviews
ORDER BY s_store_name, i_category
