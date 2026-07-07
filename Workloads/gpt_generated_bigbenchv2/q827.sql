SELECT s.category,
       s.total_quantity,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM (
    SELECT category,
           SUM(quantity) AS total_quantity
    FROM (
        SELECT i.i_category AS category,
               ss.ss_quantity AS quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT i.i_category AS category,
               ws.ws_quantity AS quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ) sc
    GROUP BY category
) s
LEFT JOIN (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
) r
ON s.category = r.category
ORDER BY s.total_quantity DESC
LIMIT 5
