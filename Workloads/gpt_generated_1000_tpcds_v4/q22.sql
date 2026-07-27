WITH store_profit AS (
    SELECT
        c.c_customer_id,
        'store' AS channel,
        SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY c.c_customer_id
),
web_profit AS (
    SELECT
        c.c_customer_id,
        'web' AS channel,
        SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY c.c_customer_id
)
SELECT
    cp.c_customer_id,
    cp.channel,
    cp.net_profit
FROM (
    SELECT * FROM store_profit
    UNION ALL
    SELECT * FROM web_profit
) cp
WHERE cp.net_profit > (
    SELECT AVG(net_profit) FROM (
        SELECT net_profit FROM store_profit
        UNION ALL
        SELECT net_profit FROM web_profit
    ) all_profit
)
ORDER BY cp.net_profit DESC
LIMIT 100
