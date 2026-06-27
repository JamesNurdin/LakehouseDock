WITH store_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        SUM(pr.pr_rating) AS rating_sum,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY pr.pr_item_id
),
category_customer_counts AS (
    SELECT
        i.i_category_id AS category_id,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM (
        SELECT ss.ss_customer_id AS customer_id, ss.ss_item_id AS item_id
        FROM store_sales ss
        UNION
        SELECT ws.ws_customer_id AS customer_id, ws.ws_item_id AS item_id
        FROM web_sales ws
    ) sc
    JOIN items i ON sc.item_id = i.i_item_id
    JOIN customers c ON sc.customer_id = c.c_customer_id
    GROUP BY i.i_category_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue,
    CASE
        WHEN SUM(COALESCE(ra.review_count, 0)) > 0
        THEN SUM(COALESCE(ra.rating_sum, 0)) / SUM(COALESCE(ra.review_count, 0))
        ELSE NULL
    END AS average_rating,
    SUM(COALESCE(ra.review_count, 0)) AS total_review_count,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
    COALESCE(ccc.distinct_customers, 0) AS distinct_customers
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
LEFT JOIN category_customer_counts ccc ON i.i_category_id = ccc.category_id
GROUP BY i.i_category_id, i.i_category_name, ccc.distinct_customers
ORDER BY total_revenue DESC
LIMIT 10
