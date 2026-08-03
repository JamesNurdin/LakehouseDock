WITH
    air_sales AS (
        SELECT
            ws.ws_order_number,
            ws.ws_net_paid_inc_ship_tax,
            ws.ws_wholesale_cost,
            ws.ws_coupon_amt,
            ws.ws_net_profit,
            CASE WHEN ws.ws_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
            ws.ws_ship_mode_sk
        FROM web_sales ws
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        WHERE sm.sm_code = 'AIR'
          AND ws.ws_net_paid_inc_ship_tax > 1000
    ),
    sea_sales AS (
        SELECT
            ws.ws_order_number,
            ws.ws_net_paid_inc_ship_tax,
            ws.ws_wholesale_cost,
            ws.ws_coupon_amt,
            ws.ws_net_profit,
            CASE WHEN ws.ws_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
            ws.ws_ship_mode_sk
        FROM web_sales ws
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        WHERE sm.sm_code = 'SEA'
          AND ws.ws_net_paid_inc_ship_tax > 1000
    ),
    air_except_sea AS (
        SELECT ws_order_number,
               ws_net_paid_inc_ship_tax,
               ws_wholesale_cost,
               ws_coupon_amt,
               ws_net_profit,
               profit_category,
               ws_ship_mode_sk
        FROM air_sales
        EXCEPT
        SELECT ws_order_number,
               ws_net_paid_inc_ship_tax,
               ws_wholesale_cost,
               ws_coupon_amt,
               ws_net_profit,
               profit_category,
               ws_ship_mode_sk
        FROM sea_sales
    ),
    high_profit_orders AS (
        SELECT DISTINCT ws_order_number
        FROM web_sales
        WHERE ws_net_profit > 2000
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY a.ws_net_paid_inc_ship_tax DESC) AS row_num,
    a.ws_order_number,
    a.ws_net_paid_inc_ship_tax,
    a.ws_wholesale_cost,
    a.ws_coupon_amt,
    a.ws_net_profit,
    a.profit_category,
    sm.sm_carrier
FROM air_except_sea a
JOIN ship_mode sm ON a.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE a.ws_order_number NOT IN (SELECT ws_order_number FROM high_profit_orders)
ORDER BY a.ws_net_paid_inc_ship_tax DESC
LIMIT 100
