WITH item_avg_ratings AS (
    SELECT i.i_item_id,
           avg(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_id,
       s.s_store_name,
       sum(ss.ss_quantity) AS total_quantity_sold,
       sum(ss.ss_quantity * i.i_price) AS total_revenue,
       sum(ss.ss_quantity * coalesce(ir.avg_rating, 0)) / nullif(sum(ss.ss_quantity), 0) AS avg_weighted_rating,
       count(distinct ss.ss_customer_id) AS distinct_customers,
       count(distinct ss.ss_item_id) AS distinct_items_sold
FROM store_sales ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_avg_ratings ir
    ON i.i_item_id = ir.i_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
