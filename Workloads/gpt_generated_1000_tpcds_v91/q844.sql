/*
Goal: Identify return reasons that appear in both store and web channels, categorize them by net profit level, rank the reasons within each category, and return the top overlapping reasons.
*/
WITH sr1 AS (
    SELECT
        r_store.r_reason_desc AS reason_desc,
        SUM(ss.ss_net_profit) AS total_net_profit,
        CASE
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE'
            ELSE 'NON_POSITIVE'
        END AS profit_category,
        ROW_NUMBER() OVER (
            PARTITION BY CASE
                WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE'
                ELSE 'NON_POSITIVE'
            END
            ORDER BY SUM(ss.ss_net_profit) DESC
        ) AS profit_rank
    FROM store_sales ss
    JOIN store_returns sr_item ON ss.ss_item_sk = sr_item.sr_item_sk
    JOIN store_returns sr_ticket ON ss.ss_ticket_number = sr_ticket.sr_ticket_number
    JOIN reason r_store ON sr_item.sr_reason_sk = r_store.r_reason_sk
    JOIN reason r_store2 ON sr_ticket.sr_reason_sk = r_store2.r_reason_sk
    GROUP BY r_store.r_reason_desc
),
wr1 AS (
    SELECT
        r_web.r_reason_desc AS reason_desc,
        SUM(ws.ws_net_profit) AS total_net_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 1000 THEN 'HIGH'
            ELSE 'LOW'
        END AS profit_category,
        ROW_NUMBER() OVER (
            PARTITION BY CASE
                WHEN SUM(ws.ws_net_profit) > 1000 THEN 'HIGH'
                ELSE 'LOW'
            END
            ORDER BY SUM(ws.ws_net_profit) DESC
        ) AS profit_rank
    FROM web_sales ws
    JOIN web_returns wr_item ON ws.ws_item_sk = wr_item.wr_item_sk
    JOIN web_returns wr_order ON ws.ws_order_number = wr_order.wr_order_number
    JOIN reason r_web ON wr_item.wr_reason_sk = r_web.r_reason_sk
    JOIN reason r_web2 ON wr_order.wr_reason_sk = r_web2.r_reason_sk
    JOIN web_page wp_sales ON ws.ws_web_page_sk = wp_sales.wp_web_page_sk
    JOIN web_page wp_returns ON wr_item.wr_web_page_sk = wp_returns.wp_web_page_sk
    GROUP BY r_web.r_reason_desc
)
SELECT reason_desc, profit_category, profit_rank
FROM sr1
INTERSECT
SELECT reason_desc, profit_category, profit_rank
FROM wr1
ORDER BY profit_rank
LIMIT 100
