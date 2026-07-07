WITH item_sentiment AS (
    SELECT i.i_item_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
store_sales_agg AS (
    SELECT ss.ss_store_id,
           ss.ss_item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
)
SELECT s.s_store_name,
       isent.i_category,
       SUM(ssa.store_quantity) AS total_quantity_sold,
       AVG(isent.avg_sentiment) AS avg_item_sentiment
FROM store_sales_agg ssa
JOIN item_sentiment isent ON ssa.ss_item_id = isent.i_item_id
JOIN stores s ON ssa.ss_store_id = s.s_store_id
GROUP BY s.s_store_name, isent.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
