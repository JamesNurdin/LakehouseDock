WITH store_sales_agg AS (
    SELECT
        ss_store_id,
        ss_item_id,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_store_id, ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_reviews_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(ir.avg_rating, 0) AS avg_rating,
    i.i_price
FROM store_sales_agg sa
LEFT JOIN stores s ON sa.ss_store_id = s.s_store_id
LEFT JOIN items i ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON sa.ss_item_id = wa.ws_item_id
LEFT JOIN item_reviews_agg ir ON sa.ss_item_id = ir.pr_item_id
WHERE COALESCE(ir.review_count, 0) >= 5
ORDER BY (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) DESC
LIMIT 10
