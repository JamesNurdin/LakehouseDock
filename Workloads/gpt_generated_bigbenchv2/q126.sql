WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_customer_id AS customer_id,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_customer_id AS customer_id,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
),
item_sales AS (
    SELECT s.item_id,
           i.i_category_id,
           i.i_category,
           i.i_price,
           s.quantity,
           s.channel,
           s.customer_id
    FROM sales s
    JOIN items i ON i.i_item_id = s.item_id
),
category_agg AS (
    SELECT i_category_id,
           i_category,
           SUM(quantity) AS total_quantity,
           SUM(CASE WHEN channel = 'store' THEN quantity ELSE 0 END) AS total_store_quantity,
           SUM(CASE WHEN channel = 'web' THEN quantity ELSE 0 END) AS total_web_quantity,
           AVG(i_price) AS avg_price,
           COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM item_sales
    GROUP BY i_category_id, i_category
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
category_review AS (
    SELECT i.i_category_id,
           AVG(r.avg_sentiment) AS avg_review_sentiment
    FROM items i
    LEFT JOIN review_agg r ON r.item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT ca.i_category_id,
       ca.i_category,
       ca.total_quantity,
       ca.total_store_quantity,
       ca.total_web_quantity,
       ca.avg_price,
       cr.avg_review_sentiment,
       ca.distinct_customer_count
FROM category_agg ca
LEFT JOIN category_review cr ON cr.i_category_id = ca.i_category_id
ORDER BY ca.total_quantity DESC
LIMIT 10
