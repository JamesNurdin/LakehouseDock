WITH unified_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_customer_id AS customer_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_customer_id AS customer_id
    FROM web_sales
),
sales_agg AS (
    SELECT us.item_id,
           SUM(us.quantity) AS total_quantity,
           COUNT(DISTINCT us.customer_id) AS distinct_customers
    FROM unified_sales us
    GROUP BY us.item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       sa.total_quantity,
       sa.distinct_customers,
       COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY sa.total_quantity DESC
LIMIT 10
