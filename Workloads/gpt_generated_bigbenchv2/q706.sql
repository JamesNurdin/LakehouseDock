WITH store_sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    ss.s_store_name,
    ss.i_category,
    ss.store_qty,
    COALESCE(ws.web_qty, 0) AS web_qty,
    ss.store_qty + COALESCE(ws.web_qty, 0) AS total_quantity,
    r.avg_sentiment,
    r.review_cnt
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws ON ss.i_category = ws.i_category
LEFT JOIN reviews_agg r ON ss.i_category = r.i_category
ORDER BY total_quantity DESC
LIMIT 10
