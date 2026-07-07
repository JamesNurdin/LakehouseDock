WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.i_category_id,
    sa.i_category,
    sa.store_quantity,
    wa.web_quantity,
    ra.avg_sentiment,
    ra.review_count
FROM store_agg sa
LEFT JOIN web_agg wa
    ON sa.i_category_id = wa.i_category_id
    AND sa.i_category = wa.i_category
LEFT JOIN review_agg ra
    ON sa.i_category_id = ra.i_category_id
    AND sa.i_category = ra.i_category
WHERE ra.avg_sentiment > 0
ORDER BY sa.s_store_name, sa.i_category
