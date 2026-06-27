WITH store_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity,
           SUM(ss_quantity * items.i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity,
           SUM(ws_quantity * items.i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
store_customers AS (
    SELECT ss_item_id AS item_id,
           COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
    FROM store_sales
    GROUP BY ss_item_id
),
web_customers AS (
    SELECT ws_item_id AS item_id,
           COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    i.i_item_id,
    i.i_name,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    sc.distinct_store_customers,
    wc.distinct_web_customers
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
LEFT JOIN store_customers sc ON i.i_item_id = sc.item_id
LEFT JOIN web_customers wc ON i.i_item_id = wc.item_id
WHERE COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) > 0
ORDER BY total_revenue DESC
LIMIT 100
