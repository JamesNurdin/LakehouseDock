/*
  Analytical query: Revenue and quantity by store (including online) and item category,
  enriched with average product rating and review count.
*/
WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
),
web_sales_agg AS (
    SELECT
        CAST(NULL AS bigint) AS s_store_id,
        'Online' AS s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    COALESCE(ss.s_store_id, ws.s_store_id) AS store_id,
    COALESCE(ss.s_store_name, ws.s_store_name) AS store_name,
    COALESCE(ss.i_category_id, ws.i_category_id) AS category_id,
    COALESCE(ss.i_category_name, ws.i_category_name) AS category_name,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(ss.store_revenue, 0) AS store_revenue,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ws.web_revenue, 0) AS web_revenue,
    ra.avg_rating,
    ra.review_count,
    (COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0)) AS total_revenue,
    (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN review_agg ra
    ON COALESCE(ss.i_category_id, ws.i_category_id) = ra.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
