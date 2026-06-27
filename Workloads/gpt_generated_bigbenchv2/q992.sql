WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_cnt
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_id,
       s.s_store_name,
       COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
       SUM(ss.ss_quantity) AS total_quantity,
       AVG(ir.avg_rating) AS avg_item_rating,
       SUM(ir.review_cnt) AS total_reviews
FROM store_sales ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_ratings ir
    ON i.i_item_id = ir.i_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_quantity DESC
LIMIT 20
