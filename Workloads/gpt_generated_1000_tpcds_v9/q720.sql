WITH filtered_customers AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_birth_month,
           c.c_salutation
    FROM tpcds.customer c
    WHERE c.c_birth_month = 8
      AND c.c_salutation = 'Mr.'
),
filtered_sales AS (
    SELECT ws.ws_bill_customer_sk,
           ws.ws_web_site_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_order_number,
           ws.ws_ship_date_sk,
           ws.ws_ship_cdemo_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 40
      AND ws.ws_ship_cdemo_sk = 174439
),
filtered_sites AS (
    SELECT w.web_site_sk,
           w.web_name,
           w.web_mkt_id,
           w.web_market_manager
    FROM tpcds.web_site w
    WHERE w.web_mkt_id = 5
      AND w.web_market_manager = 'Edward George'
)
SELECT c.c_customer_id,
       w.web_name,
       SUM(ws.ws_net_paid) AS total_net_paid,
       AVG(ws.ws_quantity) AS avg_quantity,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
       MIN(ws.ws_ship_date_sk) AS earliest_ship_date_sk,
       MAX(ws.ws_net_profit) AS max_net_profit
FROM filtered_customers c
JOIN filtered_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN filtered_sites w
  ON ws.ws_web_site_sk = w.web_site_sk
GROUP BY c.c_customer_id, w.web_name
ORDER BY total_net_paid DESC
LIMIT 100
