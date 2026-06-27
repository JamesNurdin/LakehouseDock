WITH item_avg_rating AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_name,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    AVG(COALESCE(ar.avg_rating, 0)) AS avg_item_rating
FROM store_sales ss
JOIN customers c ON ss.ss_customer_id = c.c_customer_id
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_avg_rating ar ON i.i_item_id = ar.i_item_id
GROUP BY s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
