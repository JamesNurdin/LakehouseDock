/*
  Goal: Calculate yearly net profit and distinct order count per web site and call center division for lunch‑time sales with active promotions, excluding promotions that used the radio channel, and show the top results.
*/
SELECT
    ws_site.web_name,
    d_sold.d_year,
    cc.cc_division_name,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN promotion p_main
  ON ws.ws_promo_sk = p_main.p_promo_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_start
  ON p_main.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_web_open
  ON ws_site.web_open_date_sk = d_web_open.d_date_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM promotion p_radio
        WHERE p_radio.p_promo_sk = ws.ws_promo_sk
          AND p_radio.p_channel_radio = 'Y'
      )
  AND p_main.p_purpose = 'Unknown'
  AND t.t_meal_time = 'lunch'
GROUP BY ws_site.web_name, d_sold.d_year, cc.cc_division_name
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
