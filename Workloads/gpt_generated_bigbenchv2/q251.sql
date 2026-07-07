WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.s_store_name,
    sa.i_category,
    sa.total_store_quantity,
    sa.total_store_revenue,
    wa.total_web_quantity,
    wa.total_web_revenue,
    ra.avg_sentiment
FROM store_sales_agg sa
JOIN stores s
    ON sa.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wa
    ON sa.i_category_id = wa.i_category_id
LEFT JOIN review_agg ra
    ON sa.i_category_id = ra.i_category_id
ORDER BY sa.total_store_revenue DESC
LIMIT 10
