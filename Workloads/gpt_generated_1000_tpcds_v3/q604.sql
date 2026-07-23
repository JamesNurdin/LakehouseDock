WITH ws_wr AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_ext_list_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE ws.ws_net_paid_inc_ship_tax > 1000.00
      AND ws.ws_ext_list_price BETWEEN 500 AND 10000
)
SELECT
    w.w_warehouse_name,
    ca.ca_state,
    hd.hd_income_band_sk,
    COUNT(DISTINCT ws_wr.ws_order_number) AS order_cnt,
    SUM(ws_wr.ws_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(ws_wr.ws_ext_discount_amt) AS avg_discount,
    SUM(ws_wr.wr_return_amt) AS total_return_amt,
    MIN(ws_wr.ws_net_profit) AS min_profit,
    MAX(ws_wr.ws_net_profit) AS max_profit
FROM ws_wr
INNER JOIN warehouse w
    ON ws_wr.ws_warehouse_sk = w.w_warehouse_sk
INNER JOIN customer_address ca
    ON ws_wr.ws_bill_addr_sk = ca.ca_address_sk
INNER JOIN household_demographics hd
    ON ws_wr.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE ca.ca_state = 'CA'
  AND hd.hd_income_band_sk IN (6, 11, 19)
  AND w.w_state = 'TX'
GROUP BY w.w_warehouse_name, ca.ca_state, hd.hd_income_band_sk
ORDER BY total_net_paid DESC, order_cnt DESC
LIMIT 100
