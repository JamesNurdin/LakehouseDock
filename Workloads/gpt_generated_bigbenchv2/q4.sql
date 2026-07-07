SELECT s.s_store_name,
       COUNT(DISTINCT ss.ss_transaction_id) AS total_transactions,
       SUM(ss.ss_quantity) AS total_quantity_sold,
       COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
       AVG(i.i_price) AS avg_item_price,
       AVG(pr.pr_sentiment) AS avg_review_sentiment
FROM store_sales ss
JOIN stores s
  ON ss.ss_store_id = s.s_store_id
JOIN items i
  ON ss.ss_item_id = i.i_item_id
LEFT JOIN product_reviews pr
  ON pr.pr_item_id = i.i_item_id
GROUP BY s.s_store_name
ORDER BY total_quantity_sold DESC
LIMIT 10
