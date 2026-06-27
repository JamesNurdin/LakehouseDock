WITH store_agg AS (
    SELECT
        ss_item_id AS item_id,
        COUNT(DISTINCT ss_customer_id) AS store_customer_cnt,
        COUNT(DISTINCT ss_store_id) AS store_cnt,
        SUM(ss_quantity) AS store_qty,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id AS item_id,
        COUNT(DISTINCT ws_customer_id) AS web_customer_cnt,
        SUM(ws_quantity) AS web_qty,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id AS item_id,
        COUNT(*) AS review_cnt,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_qty, 0) AS store_quantity,
    COALESCE(wa.web_qty, 0) AS web_quantity,
    COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(sa.store_customer_cnt, 0) + COALESCE(wa.web_customer_cnt, 0) AS distinct_customer_count,
    COALESCE(sa.store_cnt, 0) AS distinct_store_count,
    COALESCE(ra.review_cnt, 0) AS review_count,
    ra.avg_rating
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_revenue DESC
LIMIT 10
