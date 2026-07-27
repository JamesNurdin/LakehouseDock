WITH joined AS (
    SELECT
        ws.ws_order_number,
        ws.ws_list_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ws.ws_sales_price,
        ws.ws_net_profit,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE ws.ws_list_price > 50
      AND ws.ws_ext_discount_amt < 5
      AND w.w_warehouse_sq_ft BETWEEN 500000 AND 800000
      AND ca_bill.ca_state IN ('CA', 'TX')
      AND ca_ship.ca_state = 'NY'
)
SELECT
    w_warehouse_name,
    bill_state,
    ship_state,
    COUNT(*) AS order_cnt,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_sales_price) AS avg_sales_price,
    MIN(ws_net_profit) AS min_profit,
    MAX(ws_net_profit) AS max_profit
FROM joined
GROUP BY GROUPING SETS (
    (w_warehouse_name, bill_state, ship_state),
    (w_warehouse_name, bill_state),
    (w_warehouse_name, ship_state),
    (w_warehouse_name),
    ()
)
ORDER BY w_warehouse_name, bill_state, ship_state
LIMIT 100
