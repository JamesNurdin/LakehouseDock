WITH store_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(i.i_price * ss.ss_quantity) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(i.i_price * ws.ws_quantity) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    COALESCE(sc.i_category_id, wc.i_category_id, rc.i_category_id) AS category_id,
    COALESCE(sc.i_category_name, wc.i_category_name, rc.i_category_name) AS category_name,
    COALESCE(sc.store_quantity, 0) + COALESCE(wc.web_quantity, 0) AS total_quantity,
    COALESCE(sc.store_revenue, 0) + COALESCE(wc.web_revenue, 0) AS total_revenue,
    rc.avg_rating,
    rc.review_count
FROM store_category sc
FULL OUTER JOIN web_category wc
    ON sc.i_category_id = wc.i_category_id
    AND sc.i_category_name = wc.i_category_name
FULL OUTER JOIN review_category rc
    ON COALESCE(sc.i_category_id, wc.i_category_id) = rc.i_category_id
    AND COALESCE(sc.i_category_name, wc.i_category_name) = rc.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
