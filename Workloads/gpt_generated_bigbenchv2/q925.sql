WITH store_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
customer_pairs AS (
    SELECT ss.ss_customer_id AS customer_id, ss.ss_item_id AS item_id
    FROM store_sales ss
    UNION
    SELECT ws.ws_customer_id AS customer_id, ws.ws_item_id AS item_id
    FROM web_sales ws
),
customer_agg AS (
    SELECT item_id, COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM customer_pairs
    GROUP BY item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    ca.distinct_customer_count,
    i.i_price - i.i_comp_price AS price_diff
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
LEFT JOIN customer_agg ca ON i.i_item_id = ca.item_id
ORDER BY total_quantity DESC
LIMIT 10
