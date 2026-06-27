-- Revenue and rating summary by item category (store + web sales)
WITH item_info AS (
    SELECT
        i_item_id,
        i_category_id,
        i_category_name,
        i_price
    FROM items
),
store_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_rev
    FROM store_sales ss
    JOIN item_info i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_rev
    FROM web_sales ws
    JOIN item_info i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT
        i.i_item_id,
        SUM(pr.pr_rating) AS rating_sum,
        COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN item_info i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_metrics AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        COALESCE(sa.store_qty, 0) AS store_qty,
        COALESCE(sa.store_rev, 0) AS store_rev,
        COALESCE(wa.web_qty, 0) AS web_qty,
        COALESCE(wa.web_rev, 0) AS web_rev,
        COALESCE(ra.rating_sum, 0) AS rating_sum,
        COALESCE(ra.review_cnt, 0) AS review_cnt
    FROM item_info i
    LEFT JOIN store_agg sa
        ON i.i_item_id = sa.i_item_id
    LEFT JOIN web_agg wa
        ON i.i_item_id = wa.i_item_id
    LEFT JOIN review_agg ra
        ON i.i_item_id = ra.i_item_id
)
SELECT
    im.i_category_id,
    im.i_category_name,
    SUM(im.store_qty) AS total_store_quantity,
    SUM(im.web_qty) AS total_web_quantity,
    SUM(im.store_qty) + SUM(im.web_qty) AS total_quantity,
    SUM(im.store_rev) AS total_store_revenue,
    SUM(im.web_rev) AS total_web_revenue,
    SUM(im.store_rev) + SUM(im.web_rev) AS total_revenue,
    CASE WHEN SUM(im.review_cnt) > 0
        THEN SUM(im.rating_sum) / SUM(im.review_cnt)
        ELSE NULL
    END AS avg_rating,
    SUM(im.review_cnt) AS total_review_count
FROM item_metrics im
GROUP BY im.i_category_id, im.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
