WITH rating_per_item AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_detail AS (
    SELECT ss.ss_store_id,
           ss.ss_customer_id,
           ss.ss_item_id,
           ss.ss_quantity,
           i.i_price,
           s.s_store_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
)
SELECT ssd.ss_store_id AS store_id,
       ssd.s_store_name AS store_name,
       SUM(ssd.ss_quantity) AS total_quantity,
       SUM(ssd.ss_quantity * ssd.i_price) AS total_revenue,
       SUM(rpi.avg_rating * ssd.ss_quantity) / NULLIF(SUM(ssd.ss_quantity), 0) AS avg_item_rating,
       COUNT(DISTINCT ssd.ss_customer_id) AS distinct_customers
FROM store_sales_detail ssd
LEFT JOIN rating_per_item rpi ON ssd.ss_item_id = rpi.i_item_id
GROUP BY ssd.ss_store_id, ssd.s_store_name
ORDER BY total_revenue DESC
