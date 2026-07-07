WITH sales_by_item AS (
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
item_sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM sales_by_item
    GROUP BY item_id
),
item_reviews_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
category_customers AS (
    SELECT i.i_category AS category,
           COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales_by_item s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT i.i_category AS category,
       COUNT(DISTINCT i.i_item_id) AS num_items,
       SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
       c.distinct_customers,
       AVG(r.avg_sentiment) AS avg_sentiment,
       AVG(i.i_price) AS avg_price
FROM items i
LEFT JOIN item_sales_agg s ON i.i_item_id = s.item_id
LEFT JOIN item_reviews_agg r ON i.i_item_id = r.item_id
LEFT JOIN category_customers c ON i.i_category = c.category
GROUP BY i.i_category, c.distinct_customers
ORDER BY total_quantity_sold DESC
LIMIT 10
