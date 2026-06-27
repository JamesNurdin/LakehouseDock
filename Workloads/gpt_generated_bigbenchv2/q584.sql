WITH category_base AS (
    SELECT DISTINCT i_category_id, i_category_name
    FROM items
),
store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT s.s_store_id) AS distinct_store_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS average_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cb.i_category_id,
    cb.i_category_name,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(sa.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(sa.distinct_store_count, 0) AS distinct_store_count,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ra.average_rating, 0) AS average_rating,
    COALESCE(ra.review_count, 0) AS review_count
FROM category_base cb
LEFT JOIN store_agg sa ON cb.i_category_id = sa.i_category_id AND cb.i_category_name = sa.i_category_name
LEFT JOIN web_agg wa ON cb.i_category_id = wa.i_category_id AND cb.i_category_name = wa.i_category_name
LEFT JOIN reviews_agg ra ON cb.i_category_id = ra.i_category_id AND cb.i_category_name = ra.i_category_name
ORDER BY total_store_revenue DESC
LIMIT 20
