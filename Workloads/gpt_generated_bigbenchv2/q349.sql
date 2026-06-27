WITH store_agg AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_item_id AS item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name
),
web_agg AS (
    SELECT
        i.i_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
rating_agg AS (
    SELECT
        i.i_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_name,
    s.i_category_name,
    s.i_name,
    s.store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    s.store_quantity + COALESCE(w.web_quantity, 0) AS total_quantity,
    s.store_revenue + COALESCE(w.web_revenue, 0) AS total_revenue,
    r.avg_rating,
    r.review_count
FROM store_agg s
LEFT JOIN web_agg w
    ON s.item_id = w.item_id
LEFT JOIN rating_agg r
    ON s.item_id = r.item_id
ORDER BY total_revenue DESC
LIMIT 10
