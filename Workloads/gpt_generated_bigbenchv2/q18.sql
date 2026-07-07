WITH unified_sales AS (
    SELECT ss_customer_id AS customer_id, ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id, ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category AS category,
           SUM(us.quantity) AS total_quantity,
           SUM(us.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT us.customer_id) AS distinct_customers
    FROM unified_sales us
    JOIN items i ON us.item_id = i.i_item_id
    GROUP BY i.i_category
),
review_by_category AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    sbc.category,
    sbc.total_quantity,
    sbc.total_revenue,
    sbc.distinct_customers,
    rbc.avg_sentiment
FROM sales_by_category sbc
LEFT JOIN review_by_category rbc ON sbc.category = rbc.category
ORDER BY sbc.total_revenue DESC
