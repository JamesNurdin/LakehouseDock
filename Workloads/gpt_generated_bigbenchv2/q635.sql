WITH sales AS (
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
           SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY item_id
),
cust_agg AS (
    SELECT item_id,
           COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM sales
    GROUP BY item_id
),
rating_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_id,
       i.i_category_name,
       i.i_price,
       i.i_comp_price,
       COALESCE(sa.total_quantity, 0) AS total_quantity_sold,
       COALESCE(ca.distinct_customer_count, 0) AS distinct_customer_count,
       COALESCE(ra.avg_rating, 0) AS avg_rating,
       COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN cust_agg ca ON i.i_item_id = ca.item_id
LEFT JOIN rating_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
