WITH filtered_sales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_ship_customer_sk,
        ws_ext_ship_cost,
        ws_list_price,
        ws_net_profit
    FROM web_sales
    WHERE ws_ship_customer_sk IN (3372989, 7015489, 11888307)
      AND ws_ext_ship_cost > 100
      AND ws_list_price BETWEEN 50 AND 200
)
SELECT
    rs.wr_returning_customer_sk,
    rs.wr_return_quantity,
    SUM(rs.wr_return_amt) AS total_return_amount,
    AVG(rs.wr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(rs.wr_return_ship_cost) AS min_ship_cost,
    MAX(rs.wr_return_amt_inc_tax) AS max_return_inc_tax,
    SUM(CASE WHEN rs.wr_return_amt > 200 THEN rs.wr_return_amt ELSE 0 END) AS high_return_sum,
    SUM(rs.wr_return_amt) / NULLIF(COUNT(*), 0) AS avg_return_amount,
    ws.ws_net_profit,
    (
        SELECT MAX(ws2.ws_ext_ship_cost)
        FROM web_sales ws2
        WHERE ws2.ws_order_number = rs.wr_order_number
    ) AS max_ship_cost_for_order
FROM web_returns rs
JOIN filtered_sales ws
    ON rs.wr_item_sk = ws.ws_item_sk
   AND rs.wr_order_number = ws.ws_order_number
WHERE rs.wr_returning_customer_sk = 7810852
  AND rs.wr_return_amt > 50
  AND rs.wr_reversed_charge < 300
  AND rs.wr_fee BETWEEN 0 AND 100
  AND rs.wr_net_loss > 0
GROUP BY
    rs.wr_returning_customer_sk,
    rs.wr_return_quantity,
    ws.ws_net_profit,
    rs.wr_order_number
ORDER BY total_return_amount DESC
LIMIT 100
