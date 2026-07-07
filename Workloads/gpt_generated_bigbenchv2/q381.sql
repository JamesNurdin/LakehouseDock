WITH item_sentiment AS (
    SELECT pr.pr_item_id AS i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT ss.ss_store_id,
           ss.ss_item_id,
           SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
)
SELECT s.s_store_name,
       i.i_category,
       SUM(ssa.total_qty) AS total_quantity_sold,
       AVG(COALESCE(isent.avg_sentiment, 0)) AS avg_item_sentiment,
       COUNT(DISTINCT ssa.ss_item_id) AS distinct_items_sold
FROM store_sales_agg ssa
JOIN items i ON ssa.ss_item_id = i.i_item_id
JOIN stores s ON ssa.ss_store_id = s.s_store_id
LEFT JOIN item_sentiment isent ON i.i_item_id = isent.i_item_id
GROUP BY s.s_store_name, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
