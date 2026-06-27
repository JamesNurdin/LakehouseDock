WITH store_sales_agg AS (
    SELECT
        ss_item_id AS i_item_id,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id AS i_item_id,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id AS i_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
stores_per_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(DISTINCT ss.ss_store_id) AS distinct_stores_sold
    FROM items i
    JOIN store_sales ss ON i.i_item_id = ss.ss_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    i.i_category_name,
    i.i_category_id,
    COALESCE(SUM(sa.store_quantity), 0) + COALESCE(SUM(wa.web_quantity), 0) AS total_quantity,
    COALESCE(SUM(sa.store_revenue), 0) + COALESCE(SUM(wa.web_revenue), 0) AS total_revenue,
    AVG(ra.avg_rating) AS avg_rating,
    SUM(ra.review_count) AS total_reviews,
    COALESCE(spc.distinct_stores_sold, 0) AS distinct_stores_sold
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
LEFT JOIN stores_per_category spc
    ON i.i_category_id = spc.i_category_id
    AND i.i_category_name = spc.i_category_name
GROUP BY i.i_category_name, i.i_category_id, COALESCE(spc.distinct_stores_sold, 0)
ORDER BY total_revenue DESC
LIMIT 10
