WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY
        i.i_category_id,
        i.i_category_name,
        s.s_store_id,
        s.s_store_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    COALESCE(sa.i_category_id, wa.i_category_id) AS i_category_id,
    COALESCE(sa.i_category_name, wa.i_category_name) AS i_category_name,
    sa.s_store_id,
    sa.s_store_name,
    sa.store_quantity,
    sa.store_revenue,
    wa.web_quantity,
    wa.web_revenue,
    ra.review_count,
    ra.avg_rating
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.i_category_id = wa.i_category_id
    AND sa.i_category_name = wa.i_category_name
FULL OUTER JOIN review_agg ra
    ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
    AND COALESCE(sa.i_category_name, wa.i_category_name) = ra.i_category_name
ORDER BY i_category_id, s_store_name
