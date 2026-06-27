WITH store_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_rev
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_rev
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
rating_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.store_qty, 0)) AS total_store_quantity,
    SUM(COALESCE(sa.store_rev, 0)) AS total_store_revenue,
    SUM(COALESCE(wa.web_qty, 0)) AS total_web_quantity,
    SUM(COALESCE(wa.web_rev, 0)) AS total_web_revenue,
    AVG(r.avg_rating) AS average_item_rating,
    AVG(i.i_price - i.i_comp_price) AS average_price_difference
FROM items i
LEFT JOIN store_agg sa
    ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa
    ON i.i_item_id = wa.i_item_id
LEFT JOIN rating_agg r
    ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_store_revenue DESC
LIMIT 10
