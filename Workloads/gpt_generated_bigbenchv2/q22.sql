WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_customer_id AS customer_id,
           ss_store_id AS store_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_customer_id AS customer_id,
           NULL AS store_id
    FROM web_sales
),
sales_agg AS (
    SELECT i.i_category,
           i.i_category_id,
           SUM(cs.quantity) AS total_quantity,
           COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY i.i_category,
             i.i_category_id
),
review_agg AS (
    SELECT i.i_category,
           i.i_category_id,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category,
             i.i_category_id
)
SELECT s.i_category,
       s.i_category_id,
       s.total_quantity,
       s.distinct_customers,
       COALESCE(r.review_count, 0) AS review_count,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment
FROM sales_agg s
LEFT JOIN review_agg r
  ON s.i_category = r.i_category
 AND s.i_category_id = r.i_category_id
ORDER BY s.total_quantity DESC
LIMIT 20
