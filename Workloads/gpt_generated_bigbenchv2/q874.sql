WITH store_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_unique_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_unique_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    sa.store_quantity,
    sa.store_revenue,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count,
    sa.store_unique_customers,
    COALESCE(wa.web_unique_customers, 0) AS web_unique_customers,
    (sa.store_quantity + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    (sa.store_revenue + COALESCE(wa.web_revenue, 0)) AS total_revenue
FROM store_agg sa
JOIN stores s
    ON sa.store_id = s.s_store_id
JOIN items i
    ON sa.item_id = i.i_item_id
LEFT JOIN web_agg wa
    ON sa.item_id = wa.item_id
LEFT JOIN review_agg ra
    ON sa.item_id = ra.item_id
ORDER BY total_revenue DESC
LIMIT 100
