WITH categories AS (
    SELECT DISTINCT i_category_id, i_category_name
    FROM items
),
store_agg AS (
    SELECT i.i_category_id AS cat_id,
           SUM(ss.ss_quantity) AS total_store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers,
           COUNT(DISTINCT ss.ss_store_id) AS distinct_stores
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
web_agg AS (
    SELECT i.i_category_id AS cat_id,
           SUM(ws.ws_quantity) AS total_web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
           COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
review_agg AS (
    SELECT i.i_category_id AS cat_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
customer_agg AS (
    SELECT i.i_category_id AS cat_id,
           COUNT(DISTINCT cust.cust_id) AS distinct_customers
    FROM (
        SELECT ss.ss_customer_id AS cust_id, ss.ss_item_id AS item_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_customer_id AS cust_id, ws.ws_item_id AS item_id
        FROM web_sales ws
    ) cust
    JOIN items i ON cust.item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    cat.i_category_name,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(sa.total_store_revenue, 0.0) AS total_store_revenue,
    COALESCE(wa.total_web_revenue, 0.0) AS total_web_revenue,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count,
    COALESCE(ca.distinct_customers, 0) AS distinct_customers,
    COALESCE(sa.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(sa.distinct_stores, 0) AS distinct_stores,
    COALESCE(wa.distinct_web_customers, 0) AS distinct_web_customers
FROM categories cat
LEFT JOIN store_agg sa ON cat.i_category_id = sa.cat_id
LEFT JOIN web_agg wa ON cat.i_category_id = wa.cat_id
LEFT JOIN review_agg ra ON cat.i_category_id = ra.cat_id
LEFT JOIN customer_agg ca ON cat.i_category_id = ca.cat_id
ORDER BY cat.i_category_name
