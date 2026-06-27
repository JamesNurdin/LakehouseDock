WITH store_category_sales AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_store_revenue
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
),
web_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(i.i_price * ws.ws_quantity) AS total_web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    sc.s_store_name,
    sc.i_category_name,
    sc.total_store_quantity,
    sc.total_store_revenue,
    cr.avg_rating,
    wc.total_web_quantity,
    wc.total_web_revenue
FROM store_category_sales sc
LEFT JOIN category_ratings cr
    ON sc.i_category_id = cr.i_category_id
LEFT JOIN web_category_sales wc
    ON sc.i_category_id = wc.i_category_id
ORDER BY
    sc.s_store_name,
    sc.i_category_name
