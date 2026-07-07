WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
item_combined AS (
    SELECT
        COALESCE(ssa.i_item_id, wsa.i_item_id, ra.i_item_id) AS i_item_id,
        COALESCE(ssa.i_category, wsa.i_category, ra.i_category) AS i_category,
        COALESCE(ssa.store_quantity, 0) AS store_quantity,
        COALESCE(wsa.web_quantity, 0) AS web_quantity,
        COALESCE(ra.review_count, 0) AS review_count,
        ra.avg_sentiment
    FROM store_sales_agg ssa
    FULL OUTER JOIN web_sales_agg wsa
        ON ssa.i_item_id = wsa.i_item_id
    FULL OUTER JOIN reviews_agg ra
        ON COALESCE(ssa.i_item_id, wsa.i_item_id) = ra.i_item_id
)
SELECT
    ic.i_category,
    SUM(ic.store_quantity) AS total_store_quantity,
    SUM(ic.web_quantity) AS total_web_quantity,
    SUM(ic.store_quantity + ic.web_quantity) AS total_quantity_sold,
    SUM(ic.review_count) AS total_review_count,
    AVG(ic.avg_sentiment) AS avg_sentiment_across_items
FROM item_combined ic
GROUP BY ic.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
