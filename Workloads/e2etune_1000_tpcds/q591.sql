WITH combined AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
        ROUND((SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) / NULLIF(SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid), 0), 4) AS profit_margin
    FROM store_sales ss
    JOIN web_sales ws
        ON ss.ss_item_sk = ws.ws_item_sk
       AND ss.ss_promo_sk = ws.ws_promo_sk
       AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
       AND ss.ss_sold_time_sk = ws.ws_sold_time_sk
    WHERE ss.ss_net_paid > 100
      AND ws.ws_net_paid > 100
    GROUP BY ss.ss_sold_date_sk
    HAVING (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) > 0
)
SELECT
    sold_date_sk,
    store_txn_cnt,
    web_txn_cnt,
    store_net_paid,
    web_net_paid,
    total_net_profit,
    profit_margin,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM combined
ORDER BY total_net_profit DESC
LIMIT 10
