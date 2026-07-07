WITH combined_sales AS (
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
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity,
           COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    GROUP BY cs.item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category AS category,
       i.i_name AS item_name,
       i.i_price AS price,
       i.i_comp_price AS competitor_price,
       sa.total_quantity,
       sa.distinct_customers,
       (sa.total_quantity * i.i_price) AS total_revenue,
       ra.avg_sentiment,
       ra.review_count
FROM sales_agg sa
JOIN items i
  ON sa.item_id = i.i_item_id
LEFT JOIN review_agg ra
  ON i.i_item_id = ra.item_id
ORDER BY i.i_category, i.i_name
