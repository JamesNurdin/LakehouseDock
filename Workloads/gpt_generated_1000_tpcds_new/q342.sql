WITH sales_by_ship_mode AS (
    SELECT
        ws_ship_mode_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS cnt_orders
    FROM web_sales
    WHERE ws_ext_sales_price > 500
      AND ws_ext_discount_amt < 100
    GROUP BY ws_ship_mode_sk
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    sm.sm_type,
    s.total_sales,
    s.avg_discount,
    s.cnt_orders,
    COUNT(DISTINCT ws.ws_order_number)               AS distinct_orders,
    SUM(ws.ws_net_profit)                           AS total_profit,
    MIN(ws.ws_ext_ship_cost)                        AS min_ship_cost,
    MAX(ws.ws_ext_ship_cost)                        AS max_ship_cost,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    w.w_warehouse_name,
    td.t_hour,
    ws_site.web_name
FROM sales_by_ship_mode s
JOIN web_sales ws        ON ws.ws_ship_mode_sk = s.ws_ship_mode_sk
JOIN ship_mode sm        ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
JOIN customer c          ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN warehouse w         ON w.w_warehouse_sk = ws.ws_warehouse_sk
JOIN time_dim td         ON td.t_time_sk = ws.ws_sold_time_sk
JOIN web_site ws_site    ON ws_site.web_site_sk = ws.ws_web_site_sk
JOIN web_page wp         ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE
    sm.sm_type = 'AIR'
    AND td.t_am_pm = 'PM'
    AND td.t_second BETWEEN 10 AND 30
    AND w.w_country = 'United States'
    AND w.w_warehouse_sq_ft > 500000
    AND c.c_preferred_cust_flag = 'Y'
    AND hd.hd_buy_potential = '5000-9999'
    AND ws.ws_order_number IN (
        SELECT ws2.ws_order_number FROM web_sales ws2 WHERE ws2.ws_net_profit > 1000
        EXCEPT
        SELECT ws3.ws_order_number FROM web_sales ws3 WHERE ws3.ws_net_profit < 0
    )
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    sm.sm_type,
    s.total_sales,
    s.avg_discount,
    s.cnt_orders,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    w.w_warehouse_name,
    td.t_hour,
    ws_site.web_name
ORDER BY total_profit DESC, sm.sm_ship_mode_id
OFFSET 0 FETCH NEXT 100 ROWS ONLY
