WITH sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(cs.cs_net_paid) AS metric,
        CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS flag,
        'sale' AS src
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_list_price > 50
      AND i.i_class = 'furniture'
    GROUP BY i.i_item_id, i.i_category
),
returns AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(sr.sr_net_loss) AS metric,
        CASE WHEN SUM(sr.sr_net_loss) > 5000 THEN 'HighLoss' ELSE 'LowLoss' END AS flag,
        'return' AS src
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%size%'
      AND i.i_class = 'furniture'
    GROUP BY i.i_item_id, i.i_category
)
SELECT DISTINCT
    combined.i_item_id,
    combined.i_category,
    combined.metric,
    combined.src,
    combined.flag
FROM (
    SELECT i_item_id, i_category, metric, src, flag FROM sales
    UNION ALL
    SELECT i_item_id, i_category, metric, src, flag FROM returns
) AS combined
ORDER BY combined.metric DESC
LIMIT 100
