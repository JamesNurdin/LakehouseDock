WITH item_ratings AS (
    SELECT i.i_item_id,
           avg(pr.pr_rating) AS avg_rating,
           count(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_joined AS (
    SELECT ss.ss_transaction_id,
           ss.ss_customer_id,
           ss.ss_store_id,
           ss.ss_item_id,
           ss.ss_quantity,
           i.i_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
)
SELECT s.s_store_name,
       sum(ssj.ss_quantity * ssj.i_price) AS total_revenue,
       sum(ssj.ss_quantity) AS total_quantity,
       count(DISTINCT ssj.ss_customer_id) AS distinct_customers,
       sum(ssj.ss_quantity * coalesce(ir.avg_rating, 0)) / nullif(sum(ssj.ss_quantity), 0) AS weighted_avg_rating,
       sum(coalesce(ir.review_cnt, 0)) AS total_reviews
FROM store_sales_joined ssj
JOIN stores s ON ssj.ss_store_id = s.s_store_id
LEFT JOIN item_ratings ir ON ssj.ss_item_id = ir.i_item_id
GROUP BY s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
