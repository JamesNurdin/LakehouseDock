-- Goal: Compute per‑item total sales across store and web channels, together with average review sentiment and review count, and rank items by total sales.
WITH store_sales_agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_category AS i_category,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_category AS i_category,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_category AS i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT
    COALESCE(ssa.i_item_id, wsa.i_item_id, ra.i_item_id) AS item_id,
    COALESCE(ssa.i_category, wsa.i_category, ra.i_category) AS category,
    COALESCE(ssa.store_quantity, 0) AS store_quantity,
    COALESCE(wsa.web_quantity, 0) AS web_quantity,
    ra.avg_sentiment,
    COALESCE(ra.review_count, 0) AS review_count,
    (COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0)) AS total_quantity
FROM store_sales_agg ssa
FULL OUTER JOIN web_sales_agg wsa
    ON ssa.i_item_id = wsa.i_item_id
FULL OUTER JOIN reviews_agg ra
    ON COALESCE(ssa.i_item_id, wsa.i_item_id) = ra.i_item_id
ORDER BY total_quantity DESC
LIMIT 100
