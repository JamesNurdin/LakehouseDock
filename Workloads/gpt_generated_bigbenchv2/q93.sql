WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(DISTINCT ss.ss_store_id) AS store_count,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM items i
    JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    JOIN stores st ON st.s_store_id = ss.ss_store_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM items i
    JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
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
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id) AS i_category_id,
    COALESCE(sa.i_category_name, wa.i_category_name, ra.i_category_name) AS i_category_name,
    COALESCE(sa.store_count, 0) AS store_count,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count,
    (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    (COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON wa.i_category_id = sa.i_category_id
   AND wa.i_category_name = sa.i_category_name
FULL OUTER JOIN review_agg ra
    ON ra.i_category_id = COALESCE(sa.i_category_id, wa.i_category_id)
   AND ra.i_category_name = COALESCE(sa.i_category_name, wa.i_category_name)
ORDER BY total_revenue DESC
LIMIT 10
