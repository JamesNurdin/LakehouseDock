WITH sales AS (
    SELECT cp.cp_type AS cp_type,
           i.i_category AS i_category,
           w.w_state AS state,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
),
web AS (
    SELECT NULL AS cp_type,
           i.i_category AS i_category,
           w.w_state AS state,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
),
returns AS (
    SELECT NULL AS cp_type,
           i.i_category AS i_category,
           NULL AS state,
           -sr.sr_net_loss AS profit
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2451088
)
SELECT
    COALESCE(cp_type, 'ALL') AS catalog_page_type,
    i_category,
    COALESCE(state, 'UNKNOWN') AS state,
    SUM(profit) AS net_profit,
    COUNT(*) AS transaction_count
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM web
    UNION ALL
    SELECT * FROM returns
) t
GROUP BY
    COALESCE(cp_type, 'ALL'),
    i_category,
    COALESCE(state, 'UNKNOWN')
HAVING SUM(profit) > 0
ORDER BY net_profit DESC, transaction_count DESC
LIMIT 200
