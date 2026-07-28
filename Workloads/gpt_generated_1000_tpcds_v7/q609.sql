WITH filtered_sales AS (
    SELECT *
    FROM tpcds.web_sales
    WHERE ws_quantity >= 3
      AND ws_ext_discount_amt > 5.00
      AND ws_ship_customer_sk IN (7015489, 5407716)
      AND ws_bill_hdemo_sk = 5612
      AND ws_order_number BETWEEN 213236 AND 213250
)
SELECT
    ws.ws_web_site_sk,
    web.web_state,
    web.web_city,
    web.web_mkt_class,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_net_profit) AS min_profit,
    MAX(ws.ws_net_profit) AS max_profit
FROM filtered_sales ws
JOIN tpcds.web_site web
  ON ws.ws_web_site_sk = web.web_site_sk
WHERE web.web_rec_start_date <= DATE '2022-12-31'
  AND web.web_rec_end_date >= DATE '2022-01-01'
  AND web.web_state = 'CA'
  AND web.web_city = 'Los Angeles'
  AND web.web_mkt_class LIKE '%New%'
GROUP BY
    ws.ws_web_site_sk,
    web.web_state,
    web.web_city,
    web.web_mkt_class
ORDER BY total_net_paid DESC
LIMIT 100
