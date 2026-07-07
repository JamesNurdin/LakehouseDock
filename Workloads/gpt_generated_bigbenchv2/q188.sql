WITH store_agg AS (
    SELECT
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.i_category,
    'store' AS channel,
    s.total_quantity,
    s.avg_sentiment
FROM store_agg s
UNION ALL
SELECT
    w.i_category,
    'web' AS channel,
    w.total_quantity,
    w.avg_sentiment
FROM web_agg w
ORDER BY i_category, channel
