WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        MIN(CAST(ss_ts AS timestamp)) AS store_first_ts,
        MAX(CAST(ss_ts AS timestamp)) AS store_last_ts
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        MIN(CAST(ws_ts AS timestamp)) AS web_first_ts,
        MAX(CAST(ws_ts AS timestamp)) AS web_last_ts
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count,
        MAX(CAST(pr_ts AS timestamp)) AS latest_review_ts
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    i.i_price - i.i_comp_price AS price_margin,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    i.i_price * (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    ra.latest_review_ts,
    LEAST(
        COALESCE(sa.store_first_ts, TIMESTAMP '9999-12-31 00:00:00'),
        COALESCE(wa.web_first_ts, TIMESTAMP '9999-12-31 00:00:00')
    ) AS first_sale_ts,
    GREATEST(
        COALESCE(sa.store_last_ts, TIMESTAMP '0001-01-01 00:00:00'),
        COALESCE(wa.web_last_ts, TIMESTAMP '0001-01-01 00:00:00')
    ) AS last_sale_ts
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
