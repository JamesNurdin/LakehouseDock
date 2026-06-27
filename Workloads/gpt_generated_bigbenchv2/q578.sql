WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
rating_agg AS (
    SELECT
        i.i_category_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id
)
SELECT
    s.s_store_name,
    ss.i_category_name AS category_name,
    ss.store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    r.avg_rating
FROM store_sales_agg ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg w
    ON ss.i_category_id = w.i_category_id
LEFT JOIN rating_agg r
    ON ss.i_category_id = r.i_category_id
ORDER BY ss.store_quantity DESC
LIMIT 20
