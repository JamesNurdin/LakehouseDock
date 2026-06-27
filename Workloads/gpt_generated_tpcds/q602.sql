WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ship_mode_sk,
        ws.ws_ship_addr_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_order_number, ws.ws_ship_mode_sk, ws.ws_ship_addr_sk
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    GROUP BY wr.wr_order_number
)
SELECT
    sm.sm_type,
    ca.ca_state,
    SUM(s.total_sales) AS total_sales,
    SUM(s.total_profit) AS total_profit,
    COALESCE(SUM(r.total_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(r.total_return_loss), 0) AS total_return_loss,
    COUNT(DISTINCT s.ws_order_number) AS order_count
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ws_order_number = r.wr_order_number
JOIN ship_mode sm
    ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
    ON s.ws_ship_addr_sk = ca.ca_address_sk
GROUP BY sm.sm_type, ca.ca_state
ORDER BY total_sales DESC
LIMIT 100
