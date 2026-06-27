WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items i ON store_sales.ss_item_id = i.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items i ON web_sales.ws_item_id = i.i_item_id
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        SUM(pr_rating) AS total_rating,
        COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    SUM(COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue,
    CASE
        WHEN SUM(COALESCE(r.review_count, 0)) = 0 THEN NULL
        ELSE SUM(COALESCE(r.total_rating, 0)) / SUM(COALESCE(r.review_count, 0))
    END AS category_avg_rating,
    SUM(COALESCE(r.review_count, 0)) AS total_reviews
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
