WITH billing AS (
    SELECT ca_address_sk, ca_state AS bill_state, ca_country AS bill_country
    FROM customer_address
),
shipping AS (
    SELECT ca_address_sk, ca_state AS ship_state, ca_country AS ship_country
    FROM customer_address
)
SELECT
    b.bill_state,
    s.ship_state,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
FROM web_sales ws
JOIN billing b ON ws.ws_bill_addr_sk = b.ca_address_sk
JOIN shipping s ON ws.ws_ship_addr_sk = s.ca_address_sk
WHERE b.bill_country = 'United States'
  AND s.ship_country = 'United States'
  AND ws.ws_sold_date_sk IN (
        SELECT cp.cp_start_date_sk
        FROM catalog_page cp
        WHERE cp.cp_department = 'DEPARTMENT'
          AND cp.cp_type = 'monthly'
          AND cp.cp_start_date_sk IN (2450815, 2450906, 2451088)
    )
GROUP BY b.bill_state, s.ship_state
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
