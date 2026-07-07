WITH store_sales_agg AS (
    SELECT s.s_store_name,
           i.i_category,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category
),
reviews_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT sa.s_store_name,
       sa.i_category,
       sa.total_quantity,
       sa.total_revenue,
       sa.distinct_customers,
       ra.avg_sentiment
FROM store_sales_agg sa
LEFT JOIN reviews_agg ra ON sa.i_category = ra.i_category
ORDER BY sa.total_revenue DESC
