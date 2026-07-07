WITH store_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    sa.i_category,
    sa.store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    ra.avg_sentiment
FROM store_agg sa
JOIN stores s
    ON sa.ss_store_id = s.s_store_id
LEFT JOIN web_agg wa
    ON sa.i_category = wa.i_category
LEFT JOIN review_agg ra
    ON sa.i_category = ra.i_category
ORDER BY s.s_store_name, sa.i_category
