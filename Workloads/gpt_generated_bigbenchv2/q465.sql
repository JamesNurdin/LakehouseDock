WITH store_sales_agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        SUM(ss.ss_quantity) AS store_qty
    FROM items i
    JOIN store_sales ss
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
web_sales_agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        SUM(ws.ws_quantity) AS web_qty
    FROM items i
    JOIN web_sales ws
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
review_agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
combined AS (
    SELECT
        COALESCE(ssa.i_category, wsa.i_category) AS category,
        COALESCE(ssa.i_category_id, wsa.i_category_id) AS category_id,
        ssa.store_qty,
        wsa.web_qty
    FROM store_sales_agg ssa
    FULL OUTER JOIN web_sales_agg wsa
        ON ssa.i_category_id = wsa.i_category_id
        AND ssa.i_category = wsa.i_category
)
SELECT
    COALESCE(c.category, ra.i_category) AS category,
    COALESCE(c.category_id, ra.i_category_id) AS category_id,
    COALESCE(c.store_qty, 0) AS store_quantity,
    COALESCE(c.web_qty, 0) AS web_quantity,
    COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(ra.review_count, 0) AS review_count
FROM combined c
FULL OUTER JOIN review_agg ra
    ON c.category_id = ra.i_category_id
    AND c.category = ra.i_category
ORDER BY category
