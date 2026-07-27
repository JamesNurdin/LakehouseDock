WITH sales_agg AS (
    SELECT
        sm.sm_type AS ship_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_division_name AS division_name,
        s.s_state AS state,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year = 2001
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND ca_bill.ca_city IN ('Greenville', 'Union')
      AND ib.ib_lower_bound >= 50000
      AND cc.cc_state = 'CA'
      AND sm.sm_code = 'AIR'
    GROUP BY sm.sm_type, ib.ib_lower_bound, ib.ib_upper_bound, cc.cc_division_name, s.s_state
)
SELECT
    ship_type,
    division_name,
    state,
    total_profit,
    order_cnt,
    total_profit / order_cnt AS avg_profit_per_order,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        JOIN ship_mode sm2 ON ws2.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        WHERE sm2.sm_type = sales_agg.ship_type
    ) AS avg_profit_same_ship_type,
    (
        SELECT DISTINCT AVG(ws3.ws_net_profit) * 1.1
        FROM web_sales ws3
    ) AS overall_profit_threshold
FROM sales_agg
WHERE total_profit > (
    SELECT DISTINCT AVG(ws4.ws_net_profit) * 1.1
    FROM web_sales ws4
)
ORDER BY avg_profit_per_order DESC
LIMIT 10
