WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_customer_id AS customer_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id,
           ws_quantity,
           ws_customer_id
    FROM web_sales
),

sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM sales
    GROUP BY item_id
),

reviews_agg AS (
    SELECT pr_item_id AS item_id,
           COUNT(*) AS review_count,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating,
    COALESCE(s.distinct_customers, 0) AS distinct_customers
FROM items i
LEFT JOIN sales_agg s ON s.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
