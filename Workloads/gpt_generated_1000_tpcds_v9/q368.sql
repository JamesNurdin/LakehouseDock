WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        td.t_hour AS hour_of_day,
        'store' AS channel,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        sr.sr_return_quantity AS return_qty
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND ss.ss_net_paid > 0
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
          WHERE sr2.sr_ticket_number = ss.ss_ticket_number
            AND r2.r_reason_desc = 'Did not like the make'
      )
),
web_base AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        td.t_hour AS hour_of_day,
        'web' AS channel,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        wr.wr_return_quantity AS return_qty
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND ws.ws_net_paid > 0
)
SELECT
    channel,
    hour_of_day,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(COALESCE(return_qty, 0)) AS total_returns_quantity,
    COUNT(DISTINCT sold_date_sk) AS distinct_sale_days,
    (SELECT AVG(np) FROM (
        SELECT DISTINCT ss.ss_net_profit AS np FROM store_sales ss
        UNION ALL
        SELECT DISTINCT ws.ws_net_profit AS np FROM web_sales ws
    ) profit_union) AS avg_net_profit_all_channels
FROM (
    SELECT * FROM base_sales
    UNION ALL
    SELECT * FROM web_base
) AS all_sales
GROUP BY GROUPING SETS (
    (channel, hour_of_day),
    (channel),
    ()
)
ORDER BY channel, hour_of_day
LIMIT 100
