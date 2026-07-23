-- Goal: Compute total net profit and loss by catalog department, ship mode, and hour of day across catalog, web, and store channels, 
-- filtered to catalog orders with high profit, and demonstrate deep joins, reusable dimension aliases, 
-- a subquery with DISTINCT, and ordering.
SELECT
    cp.cp_department,
    sm.sm_type,
    td_cs.t_hour AS hour_of_day,
    SUM(cs.cs_net_profit)               AS total_catalog_net_profit,
    SUM(ws.ws_net_profit)               AS total_web_net_profit,
    SUM(ss.ss_net_profit)               AS total_store_net_profit,
    SUM(sr.sr_net_loss)                 AS total_store_return_loss,
    COUNT(DISTINCT cs.cs_order_number)  AS distinct_catalog_orders
FROM catalog_page cp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_cs
    ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN household_demographics hd_cs_bill
    ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
JOIN household_demographics hd_cs_ship
    ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN household_demographics hd_ws_ship
    ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN store_sales ss
    ON ss.ss_sold_time_sk = td_cs.t_time_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
WHERE cs.cs_order_number IN (
    SELECT DISTINCT cs2.cs_order_number
    FROM catalog_sales cs2
    WHERE cs2.cs_net_profit > 1000
)
GROUP BY cp.cp_department, sm.sm_type, td_cs.t_hour
ORDER BY total_catalog_net_profit DESC
LIMIT 100
