WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity,
        SUM(ss_quantity * i_price) AS total_store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_quantity,
        SUM(ws_quantity * i_price) AS total_web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(sa.total_store_revenue, 0) + COALESCE(wa.total_web_revenue, 0)) AS total_revenue,
    SUM(COALESCE(r.review_count, 0)) AS total_reviews,
    AVG(r.avg_rating) AS avg_item_rating
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.pr_item_id
WHERE i.i_price > 10
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
