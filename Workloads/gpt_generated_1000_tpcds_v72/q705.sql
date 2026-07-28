WITH sales_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           COALESCE(SUM(ss.ss_net_paid), 0) AS store_net_paid,
           COALESCE(SUM(ws.ws_net_paid), 0) AS web_net_paid,
           COALESCE(SUM(cs.cs_net_paid), 0) AS catalog_net_paid
    FROM item i
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales   ws ON ws.ws_item_sk   = i.i_item_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_category
)
SELECT DISTINCT
    i_item_id,
    i_category,
    CASE WHEN store_net_paid > 10000 THEN 'High Store' ELSE 'Low Store' END AS sales_channel,
    store_net_paid AS net_paid
FROM sales_agg
WHERE store_net_paid > 0
UNION ALL
SELECT DISTINCT
    i_item_id,
    i_category,
    CASE WHEN web_net_paid > 10000 THEN 'High Web' ELSE 'Low Web' END AS sales_channel,
    web_net_paid AS net_paid
FROM sales_agg
WHERE web_net_paid > 0
ORDER BY net_paid DESC
LIMIT 100
