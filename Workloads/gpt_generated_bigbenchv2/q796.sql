WITH sales_with_reviews AS (
    SELECT
        s.s_store_name AS s_store_name,
        i.i_category AS i_category,
        ss.ss_quantity AS ss_quantity,
        pr.pr_sentiment AS pr_sentiment,
        c.c_customer_id AS c_customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
)
SELECT
    s_store_name,
    i_category,
    SUM(ss_quantity) AS total_quantity_sold,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    AVG(pr_sentiment) AS avg_review_sentiment
FROM sales_with_reviews
GROUP BY s_store_name, i_category
ORDER BY total_quantity_sold DESC
LIMIT 100
