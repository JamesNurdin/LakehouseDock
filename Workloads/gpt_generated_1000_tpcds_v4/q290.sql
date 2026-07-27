WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk
    FROM web_sales ws
    WHERE EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
          AND sm.sm_carrier = 'UPS'
    )
)
SELECT
    ws_site.web_name,
    sm.sm_carrier,
    SUM(ws_agg.ws_net_paid) AS total_net_paid,
    SUM(ws_agg.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_agg.ws_order_number) AS order_cnt,
    RANK() OVER (ORDER BY SUM(ws_agg.ws_net_profit) DESC) AS profit_rank,
    MIN(td.t_hour) AS first_hour,
    MAX(td.t_minute) AS last_minute
FROM sales_agg ws_agg
JOIN time_dim td
  ON ws_agg.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
  ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws_site
  ON ws_agg.ws_web_site_sk = ws_site.web_site_sk
JOIN customer c_bill
  ON ws_agg.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
  ON ws_agg.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship
  ON ws_agg.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship
  ON ws_agg.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_address ca_bill_current
  ON c_bill.c_current_addr_sk = ca_bill_current.ca_address_sk
JOIN customer_address ca_ship_current
  ON c_ship.c_current_addr_sk = ca_ship_current.ca_address_sk
WHERE c_bill.c_preferred_cust_flag = 'Y'
  AND ws_site.web_rec_end_date > DATE '2000-01-01'
GROUP BY
    ws_site.web_name,
    sm.sm_carrier
ORDER BY total_net_profit DESC
LIMIT 100
