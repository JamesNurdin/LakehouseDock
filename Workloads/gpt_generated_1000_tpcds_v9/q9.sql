SELECT
    ws.ws_ship_mode_sk,
    ws.ws_web_page_sk,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    MIN(wr.wr_net_loss) AS min_net_loss,
    MAX(wr.wr_net_loss) AS max_net_loss,
    (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_fee > 80.00) AS total_high_fee_return_cnt
FROM web_sales ws
JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
WHERE ws.ws_ship_mode_sk IN (1, 5, 15)
  AND ws.ws_web_page_sk BETWEEN 200 AND 2500
  AND ws.ws_ext_wholesale_cost > 1000.00
  AND wr.wr_fee > 30.00
  AND wr.wr_return_quantity >= 30
GROUP BY ws.ws_ship_mode_sk, ws.ws_web_page_sk
ORDER BY total_net_profit DESC
LIMIT 100
