WITH ws AS (
    SELECT i.i_category AS category,
           sm.sm_type AS ship_mode_type,
           SUM(wsales.ws_ext_sales_price) AS total_sales,
           SUM(wsales.ws_net_profit) AS total_profit,
           COUNT(*) AS txn_cnt
    FROM web_sales wsales
    JOIN item i ON wsales.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON wsales.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE wsales.ws_sold_date_sk BETWEEN 2450815 AND 2450997
    GROUP BY i.i_category, sm.sm_type
),
sr AS (
    SELECT i.i_category AS category,
           s.s_state AS state,
           SUM(sr.sr_return_quantity) AS total_return_qty,
           SUM(sr.sr_return_amt) AS total_return_amt,
           SUM(sr.sr_net_loss) AS total_net_loss,
           COUNT(*) AS return_txn_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2450997
    GROUP BY i.i_category, s.s_state
)
SELECT ws.category,
       ws.ship_mode_type,
       sr.state,
       ws.total_sales,
       ws.total_profit,
       sr.total_return_qty,
       sr.total_return_amt,
       sr.total_net_loss,
       (ws.total_profit - sr.total_net_loss) AS net_profit_after_returns
FROM ws
JOIN sr ON ws.category = sr.category
WHERE ws.total_sales > 10000
  AND sr.total_net_loss > 0
ORDER BY net_profit_after_returns DESC
LIMIT 50
