WITH
    store_sales_agg AS (
        SELECT
            i.i_item_id      AS item_id,
            i.i_category_id  AS category_id,
            i.i_category_name AS category_name,
            s.s_store_id     AS store_id,
            SUM(ss.ss_quantity)                     AS store_quantity,
            SUM(ss.ss_quantity * i.i_price)         AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name, s.s_store_id
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_id      AS item_id,
            i.i_category_id  AS category_id,
            i.i_category_name AS category_name,
            SUM(ws.ws_quantity)                     AS web_quantity,
            SUM(ws.ws_quantity * i.i_price)         AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
    ),
    reviews_agg AS (
        SELECT
            i.i_item_id      AS item_id,
            i.i_category_id  AS category_id,
            i.i_category_name AS category_name,
            AVG(pr.pr_rating)                         AS avg_rating,
            COUNT(*)                                   AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
    )
SELECT
    COALESCE(ss.category_id, ws.category_id, r.category_id)   AS category_id,
    COALESCE(ss.category_name, ws.category_name, r.category_name) AS category_name,
    SUM(ss.store_quantity)                                   AS total_store_quantity,
    SUM(ss.store_revenue)                                    AS total_store_revenue,
    SUM(ws.web_quantity)                                    AS total_web_quantity,
    SUM(ws.web_revenue)                                      AS total_web_revenue,
    SUM(ss.store_quantity) + SUM(ws.web_quantity)          AS total_quantity,
    SUM(ss.store_revenue) + SUM(ws.web_revenue)            AS total_revenue,
    AVG(r.avg_rating)                                        AS avg_item_rating,
    SUM(r.review_count)                                      AS total_review_count,
    COUNT(DISTINCT ss.store_id)                              AS distinct_stores_selling
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.item_id = ws.item_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.item_id, ws.item_id) = r.item_id
GROUP BY
    COALESCE(ss.category_id, ws.category_id, r.category_id),
    COALESCE(ss.category_name, ws.category_name, r.category_name)
ORDER BY total_revenue DESC
LIMIT 10
