WITH combined_sales AS (
    SELECT ss_customer_id AS customer_id, ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id, ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity,
           COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    GROUP BY cs.item_id
),
review_agg AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(COALESCE(sa.total_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_item_price,
       AVG(ra.avg_sentiment) AS avg_review_sentiment,
       SUM(COALESCE(ra.review_count, 0)) AS total_review_count,
       SUM(COALESCE(sa.distinct_customers, 0)) AS total_distinct_customers
FROM items i
LEFT JOIN sales_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
