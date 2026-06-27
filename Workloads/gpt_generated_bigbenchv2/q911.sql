WITH store_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss_customer_id) AS store_customer_count
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws_customer_id) AS web_customer_count
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
customer_agg AS (
    SELECT item_id,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM (
        SELECT ss_item_id AS item_id, ss_customer_id AS customer_id
        FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_customer_id AS customer_id
        FROM web_sales
    )
    GROUP BY item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       COALESCE(sa.store_quantity, 0) AS store_quantity,
       COALESCE(wa.web_quantity, 0) AS web_quantity,
       COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
       (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price AS total_revenue,
       ra.avg_rating,
       ra.review_count,
       ca.distinct_customers
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
LEFT JOIN customer_agg ca ON i.i_item_id = ca.item_id
ORDER BY total_revenue DESC
LIMIT 10
