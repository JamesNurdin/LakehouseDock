WITH base AS (
    SELECT
        ca.ca_state,
        sm.sm_code,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    JOIN customer cust
        ON ws.ws_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE sm.sm_code = 'AIR'
      AND cust.c_preferred_cust_flag = 'Y'
      AND wr.wr_reversed_charge > 100
      AND wr.wr_return_ship_cost < 500
      AND ws.ws_quantity > 2
),
agg AS (
    SELECT
        ca_state,
        sm_code,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM base
    GROUP BY ca_state, sm_code
)
SELECT
    agg.ca_state,
    agg.sm_code,
    agg.total_profit,
    agg.order_cnt,
    RANK() OVER (ORDER BY agg.total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank ASC, agg.ca_state
