WITH avg_sentiment AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_name,
       SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN avg_sentiment avgs ON ss.ss_item_id = avgs.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
WHERE avgs.avg_sentiment > 0
GROUP BY s.s_store_name
ORDER BY total_quantity DESC
LIMIT 10
