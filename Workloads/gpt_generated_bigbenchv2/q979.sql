WITH item_ratings AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
    AVG(ir.avg_rating) AS avg_item_rating
FROM store_sales ss
JOIN items i
    ON ss.ss_item_id = i.i_item_id
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_ratings ir
    ON i.i_item_id = ir.pr_item_id
GROUP BY s.s_store_name, i.i_category_name
ORDER BY total_revenue DESC
