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
    SELECT item_id,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM combined_sales
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       i.i_name,
       i.i_price,
       s.total_quantity,
       s.distinct_customers,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM sales_agg s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.pr_item_id
ORDER BY s.total_quantity DESC
LIMIT 10
