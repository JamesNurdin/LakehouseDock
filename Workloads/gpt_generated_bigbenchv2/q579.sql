WITH store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
distinct_customers AS (
    SELECT item_id AS i_item_id,
           COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM (
        SELECT ss_customer_id AS customer_id, ss_item_id AS item_id
        FROM store_sales
        UNION ALL
        SELECT ws_customer_id AS customer_id, ws_item_id AS item_id
        FROM web_sales
    ) AS combined
    GROUP BY item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity_sold,
       r.avg_rating,
       r.review_count,
       d.distinct_customer_count
FROM items i
LEFT JOIN store_sales_agg s ON s.i_item_id = i.i_item_id
LEFT JOIN web_sales_agg w ON w.i_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.i_item_id = i.i_item_id
LEFT JOIN distinct_customers d ON d.i_item_id = i.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 5
