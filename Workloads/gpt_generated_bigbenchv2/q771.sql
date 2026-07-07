WITH combined_sales AS (
    SELECT ss_transaction_id AS transaction_id,
           ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_store_id AS store_id,
           ss_ts AS ts
    FROM store_sales
    UNION ALL
    SELECT ws_transaction_id AS transaction_id,
           ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity,
           CAST(NULL AS bigint) AS store_id,
           ws_ts AS ts
    FROM web_sales
),
sales_agg AS (
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity,
           SUM(cs.quantity * i.i_price) AS total_revenue
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY cs.item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       s.total_quantity,
       s.total_revenue,
       r.avg_sentiment
FROM items i
JOIN sales_agg s ON i.i_item_id = s.item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
ORDER BY s.total_revenue DESC
LIMIT 10
