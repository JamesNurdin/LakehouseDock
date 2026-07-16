WITH base AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        c_bill.c_birth_month AS birth_month,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS cnt
    FROM web_sales ws
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_bill
      ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
      ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    WHERE c_bill.c_preferred_cust_flag = 'Y'
      AND c_bill.c_birth_year >= 1960
      AND t.t_hour BETWEEN 8 AND 12
      AND sm.sm_type IN ('AIR', 'GROUND')
      AND ws.ws_ext_discount_amt > 2.00
    GROUP BY sm.sm_type, c_bill.c_birth_month
    HAVING COUNT(*) > 200
)
SELECT
    ship_mode_type,
    birth_month,
    order_cnt,
    total_profit,
    avg_discount,
    total_quantity,
    RANK() OVER (PARTITION BY birth_month ORDER BY total_profit DESC) AS profit_rank
FROM base
ORDER BY total_profit DESC
LIMIT 100
