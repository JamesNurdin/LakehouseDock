SELECT
    s.s_store_name,
    i.i_category_name,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
    AVG(i.i_price) AS avg_price,
    AVG(pr.pr_rating) AS avg_rating,
    COUNT(pr.pr_review_id) AS review_count
FROM store_sales ss
JOIN items i
  ON ss.ss_item_id = i.i_item_id
JOIN stores s
  ON ss.ss_store_id = s.s_store_id
LEFT JOIN product_reviews pr
  ON pr.pr_item_id = i.i_item_id
GROUP BY s.s_store_name, i.i_category_name
ORDER BY s.s_store_name, total_quantity DESC
