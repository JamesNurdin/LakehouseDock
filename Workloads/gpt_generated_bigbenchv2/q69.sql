SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_store_quantity,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
    AVG(pr.pr_sentiment) AS avg_review_sentiment
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY s.s_store_id, s.s_store_name, i.i_category
ORDER BY total_store_quantity DESC
LIMIT 10
