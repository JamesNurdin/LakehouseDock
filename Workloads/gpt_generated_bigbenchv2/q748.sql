WITH sales AS (
    SELECT
        i.i_category,
        i.i_category_id,
        i.i_price,
        ss.ss_quantity,
        pr.pr_sentiment,
        c.c_customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
)
SELECT
    i_category,
    i_category_id,
    SUM(ss_quantity) AS total_quantity_sold,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    AVG(i_price) AS avg_price,
    AVG(pr_sentiment) AS avg_sentiment
FROM sales
GROUP BY i_category, i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
