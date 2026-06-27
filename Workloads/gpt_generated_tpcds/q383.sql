WITH unified_sales AS (
    -- Store channel sales + returns
    SELECT i.i_category AS category,
           ss.ss_net_profit AS net_profit,
           COALESCE(sr.sr_net_loss, 0) AS return_loss
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk

    UNION ALL

    -- Catalog channel sales + returns
    SELECT i.i_category AS category,
           cs.cs_net_profit AS net_profit,
           COALESCE(cr.cr_net_loss, 0) AS return_loss
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk

    UNION ALL

    -- Web channel sales + returns
    SELECT i.i_category AS category,
           ws.ws_net_profit AS net_profit,
           COALESCE(wr.wr_net_loss, 0) AS return_loss
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
)
SELECT
    category,
    SUM(net_profit) AS total_net_profit,
    SUM(return_loss) AS total_return_loss,
    SUM(net_profit) - SUM(return_loss) AS net_profit_after_returns
FROM unified_sales
GROUP BY category
ORDER BY net_profit_after_returns DESC
LIMIT 10
