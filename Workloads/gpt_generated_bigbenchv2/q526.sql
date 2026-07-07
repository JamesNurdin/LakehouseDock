WITH sales_union AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sentiment AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    SUM(su.quantity) AS total_quantity,
    SUM(su.quantity * i.i_price) AS total_spend,
    CASE
        WHEN SUM(su.quantity) > 0 THEN SUM(su.quantity * COALESCE(item_sent.avg_sentiment, 0)) / SUM(su.quantity)
        ELSE NULL
    END AS weighted_avg_sentiment
FROM sales_union su
JOIN customers c
    ON su.customer_id = c.c_customer_id
JOIN items i
    ON su.item_id = i.i_item_id
LEFT JOIN item_sentiment item_sent
    ON su.item_id = item_sent.item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spend DESC
LIMIT 10
