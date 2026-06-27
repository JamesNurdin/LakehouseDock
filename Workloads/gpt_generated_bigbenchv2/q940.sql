WITH item_rating_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT ss.ss_item_id) AS distinct_items_sold,
    AVG(ir.avg_rating) AS average_item_rating,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_rating_agg ir ON i.i_item_id = ir.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_id, s.s_store_name
HAVING SUM(ss.ss_quantity * i.i_price) > 1000
ORDER BY total_revenue DESC
LIMIT 5
