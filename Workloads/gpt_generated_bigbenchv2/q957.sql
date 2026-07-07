WITH sales AS (
    SELECT ss_item_id AS item_id, SUM(ss_quantity) AS quantity_sold
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT ws_item_id AS item_id, SUM(ws_quantity) AS quantity_sold
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT item_id, SUM(quantity_sold) AS total_quantity_sold
    FROM sales
    GROUP BY item_id
),
customer_purchases AS (
    SELECT ss_item_id AS item_id, ss_customer_id AS customer_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_customer_id AS customer_id
    FROM web_sales
),
item_reviews AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(its.total_quantity_sold, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_price,
       SUM(COALESCE(ir.review_count, 0)) AS total_review_count,
       AVG(ir.avg_sentiment) AS avg_sentiment,
       COUNT(DISTINCT cp.customer_id) AS distinct_customers
FROM items i
LEFT JOIN item_sales its
    ON i.i_item_id = its.item_id
LEFT JOIN item_reviews ir
    ON i.i_item_id = ir.item_id
LEFT JOIN (
    SELECT cp.item_id, cp.customer_id
    FROM customer_purchases cp
) cp
    ON i.i_item_id = cp.item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
