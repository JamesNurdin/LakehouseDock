SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(i.i_price * ss.ss_quantity) AS total_revenue,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(pr.pr_review_id) AS review_count
FROM store_sales ss
JOIN customers c ON ss.ss_customer_id = c.c_customer_id
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_name,
    i.i_category
ORDER BY total_revenue DESC
LIMIT 10
