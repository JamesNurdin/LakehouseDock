WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_qty,
        COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_qty,
        COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    i.i_item_id,
    i.i_name,
    COALESCE(sa.total_store_qty, 0) AS total_store_quantity,
    COALESCE(wa.total_web_qty, 0) AS total_web_quantity,
    COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0) AS total_quantity_sold,
    COALESCE(sa.distinct_store_customers, 0) + COALESCE(wa.distinct_web_customers, 0) AS distinct_customers,
    ra.avg_rating,
    ra.review_count,
    (COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0)) * i.i_price AS total_revenue,
    RANK() OVER (
        PARTITION BY i.i_category_id
        ORDER BY (COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0)) * i.i_price DESC
    ) AS revenue_rank_in_category
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
WHERE i.i_category_id IS NOT NULL
ORDER BY total_quantity_sold DESC
LIMIT 20
