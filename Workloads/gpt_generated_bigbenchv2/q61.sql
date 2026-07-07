WITH store_sales_agg AS (
    SELECT
        i.i_category,
        i.i_item_id,
        i.i_price,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id, i.i_price
),
web_sales_agg AS (
    SELECT
        i.i_category,
        i.i_item_id,
        i.i_price,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id, i.i_price
),
reviews_agg AS (
    SELECT
        i.i_category,
        i.i_item_id,
        i.i_price,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id, i.i_price
)
SELECT
    COALESCE(ss.i_category, ws.i_category, r.i_category) AS category,
    COALESCE(ss.i_item_id, ws.i_item_id, r.i_item_id) AS item_id,
    COALESCE(ss.i_price, ws.i_price, r.i_price) AS price,
    ss.store_quantity,
    ss.store_revenue,
    ws.web_quantity,
    ws.web_revenue,
    r.avg_sentiment,
    r.review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_item_id = ws.i_item_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.i_item_id, ws.i_item_id) = r.i_item_id
ORDER BY category, item_id
