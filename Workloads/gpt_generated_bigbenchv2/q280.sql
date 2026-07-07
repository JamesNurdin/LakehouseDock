WITH sales_agg AS (
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity,
           SUM(i.i_price * cs.quantity) AS total_revenue,
           COUNT(DISTINCT cs.customer_id) AS distinct_customers,
           SUM(CASE WHEN cs.sales_channel = 'store' THEN cs.quantity ELSE 0 END) AS store_quantity,
           SUM(CASE WHEN cs.sales_channel = 'web' THEN cs.quantity ELSE 0 END) AS web_quantity
    FROM (
        SELECT ss.ss_customer_id AS customer_id,
               ss.ss_item_id AS item_id,
               ss.ss_quantity AS quantity,
               'store' AS sales_channel
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_customer_id AS customer_id,
               ws.ws_item_id AS item_id,
               ws.ws_quantity AS quantity,
               'web' AS sales_channel
        FROM web_sales ws
    ) cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY cs.item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       i.i_item_id,
       i.i_name,
       sa.total_quantity,
       sa.total_revenue,
       sa.distinct_customers,
       sa.store_quantity,
       sa.web_quantity,
       ra.avg_sentiment,
       ra.review_count
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY sa.total_revenue DESC
LIMIT 10
