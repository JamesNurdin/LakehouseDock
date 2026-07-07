WITH item_review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT ss.ss_store_id AS store_id,
           ss.ss_item_id AS item_id,
           ss.ss_customer_id AS customer_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
),
store_item_sales AS (
    SELECT ss.store_id,
           i.i_item_id,
           i.i_price,
           ss.quantity,
           ss.customer_id,
           ra.avg_sentiment,
           ra.review_count
    FROM store_sales_agg ss
    JOIN items i ON ss.item_id = i.i_item_id
    LEFT JOIN item_review_agg ra ON i.i_item_id = ra.item_id
)
SELECT s.s_store_name,
       SUM(si.quantity) AS total_quantity_sold,
       SUM(si.quantity * si.i_price) AS total_revenue,
       CASE WHEN SUM(si.quantity) > 0 THEN SUM(COALESCE(si.avg_sentiment, 0) * si.quantity) / SUM(si.quantity) ELSE NULL END AS weighted_avg_review_sentiment,
       COUNT(DISTINCT si.customer_id) AS distinct_customers
FROM store_item_sales si
JOIN stores s ON si.store_id = s.s_store_id
GROUP BY s.s_store_name
ORDER BY total_quantity_sold DESC
