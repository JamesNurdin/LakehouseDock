WITH sales_data AS (
    SELECT
        s.s_store_name,
        i.i_category,
        ss.ss_quantity,
        i.i_price,
        pr.pr_sentiment
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    LEFT JOIN product_reviews pr
        ON i.i_item_id = pr.pr_item_id
)
SELECT
    s_store_name,
    i_category,
    SUM(ss_quantity * i_price) AS total_revenue,
    AVG(pr_sentiment) AS avg_sentiment
FROM sales_data
GROUP BY s_store_name, i_category
ORDER BY total_revenue DESC
LIMIT 10
