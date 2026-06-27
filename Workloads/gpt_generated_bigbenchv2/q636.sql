/*
  Analytical query: Top‑5 best‑selling items per category across store and web channels,
  including sales quantities, revenues, average rating and review count.
*/
WITH store_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_store_id) AS store_count,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
rating_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price,
        COALESCE(sa.store_quantity, 0) AS store_quantity,
        COALESCE(wa.web_quantity, 0) AS web_quantity,
        COALESCE(sa.store_revenue, 0) AS store_revenue,
        COALESCE(wa.web_revenue, 0) AS web_revenue,
        COALESCE(ra.avg_rating, 0) AS avg_rating,
        COALESCE(ra.review_count, 0) AS review_count,
        COALESCE(sa.store_count, 0) AS store_count,
        COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
        COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue
    FROM items i
    LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
    LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
    LEFT JOIN rating_agg ra ON i.i_item_id = ra.item_id
),
ranked_items AS (
    SELECT
        i_item_id,
        i_name,
        i_category_name,
        i_price,
        store_quantity,
        web_quantity,
        total_quantity,
        total_revenue,
        avg_rating,
        review_count,
        store_count,
        ROW_NUMBER() OVER (PARTITION BY i_category_name ORDER BY total_quantity DESC) AS category_rank
    FROM item_sales
)
SELECT
    i_item_id,
    i_name,
    i_category_name,
    i_price,
    store_quantity,
    web_quantity,
    total_quantity,
    total_revenue,
    avg_rating,
    review_count,
    store_count
FROM ranked_items
WHERE category_rank <= 5
ORDER BY i_category_name, total_quantity DESC
