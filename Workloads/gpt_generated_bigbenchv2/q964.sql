SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COUNT(pr.pr_review_id) AS review_count,
       AVG(pr.pr_sentiment) AS avg_sentiment
FROM product_reviews pr
JOIN items i
  ON pr.pr_item_id = i.i_item_id
GROUP BY i.i_item_id, i.i_name, i.i_category, i.i_price
HAVING COUNT(pr.pr_review_id) >= 5
ORDER BY AVG(pr.pr_sentiment) DESC
LIMIT 10
