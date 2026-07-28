/* goal: summarize web sales profitability by year, web page URL and ship mode, showing average list price per page and restricting to ship modes that exist as 'Air' */
WITH avg_price_per_page AS (
    SELECT
        ws.ws_web_page_sk,
        AVG(ws.ws_list_price) AS avg_list_price
    FROM web_sales ws
    GROUP BY ws.ws_web_page_sk
)
SELECT
    d_sold.d_year,
    wp.wp_url,
    sm.sm_type,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS order_cnt,
    ap.avg_list_price
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN avg_price_per_page ap
  ON ap.ws_web_page_sk = ws.ws_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM ship_mode sm2
    WHERE sm2.sm_ship_mode_sk = ws.ws_ship_mode_sk
      AND sm2.sm_type = 'Air'
)
GROUP BY
    d_sold.d_year,
    wp.wp_url,
    sm.sm_type,
    ap.avg_list_price
ORDER BY total_profit DESC
LIMIT 100
