WITH item_avg_rating AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_enriched AS (
    SELECT ss.ss_transaction_id AS transaction_id,
           ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           i.i_category_id,
           i.i_category_name,
           i.i_price,
           ss.ss_quantity AS quantity,
           COALESCE(r.avg_rating, 0) AS avg_rating,
           'store' AS channel
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_avg_rating r
      ON i.i_item_id = r.i_item_id
),
web_sales_enriched AS (
    SELECT ws.ws_transaction_id AS transaction_id,
           ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           i.i_category_id,
           i.i_category_name,
           i.i_price,
           ws.ws_quantity AS quantity,
           COALESCE(r.avg_rating, 0) AS avg_rating,
           'web' AS channel
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_avg_rating r
      ON i.i_item_id = r.i_item_id
),
all_sales AS (
    SELECT transaction_id,
           customer_id,
           item_id,
           i_category_id,
           i_category_name,
           i_price,
           quantity,
           avg_rating,
           channel
    FROM store_sales_enriched
    UNION ALL
    SELECT transaction_id,
           customer_id,
           item_id,
           i_category_id,
           i_category_name,
           i_price,
           quantity,
           avg_rating,
           channel
    FROM web_sales_enriched
)
SELECT
    channel,
    i_category_id,
    i_category_name,
    SUM(quantity * i_price) AS total_revenue,
    SUM(quantity) AS total_quantity,
    AVG(avg_rating) AS avg_item_rating,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM all_sales
GROUP BY
    channel,
    i_category_id,
    i_category_name
ORDER BY total_revenue DESC
LIMIT 20
