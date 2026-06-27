WITH item_ratings AS (
    SELECT i.i_item_id,
           avg(pr.pr_rating) AS avg_rating,
           count(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT ss.ss_store_id,
           ss.ss_item_id,
           sum(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
store_customer_counts AS (
    SELECT ss.ss_store_id,
           count(DISTINCT ss.ss_customer_id) AS distinct_customer_count
    FROM store_sales ss
    GROUP BY ss.ss_store_id
)
SELECT s.s_store_id,
       s.s_store_name,
       sum(ssa.total_quantity) AS total_quantity_sold,
       sum(ssa.total_quantity * i.i_price) AS total_revenue,
       avg(ir.avg_rating) AS avg_item_rating,
       sum(ir.review_count) AS total_review_count,
       sc.distinct_customer_count
FROM store_sales_agg ssa
JOIN items i ON ssa.ss_item_id = i.i_item_id
JOIN stores s ON ssa.ss_store_id = s.s_store_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
JOIN store_customer_counts sc ON ssa.ss_store_id = sc.ss_store_id
GROUP BY s.s_store_id, s.s_store_name, sc.distinct_customer_count
ORDER BY total_revenue DESC
LIMIT 10
