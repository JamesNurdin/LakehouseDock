WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category AS category,
           SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_by_category AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
customers_by_category AS (
    SELECT i.i_category AS category,
           c.c_customer_id AS customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION
    SELECT i.i_category AS category,
           c.c_customer_id AS customer_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT 
    sbc.category,
    COALESCE(sbc.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rbc.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(rbc.review_count, 0) AS total_review_count,
    COUNT(DISTINCT cbc.customer_id) AS distinct_customers
FROM sales_by_category sbc
LEFT JOIN reviews_by_category rbc ON sbc.category = rbc.category
LEFT JOIN customers_by_category cbc ON sbc.category = cbc.category
GROUP BY sbc.category, sbc.total_quantity, rbc.avg_sentiment, rbc.review_count
ORDER BY total_quantity_sold DESC
