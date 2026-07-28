WITH billed AS (
   SELECT ca.ca_city AS city,
          SUM(ws.ws_net_paid_inc_tax) AS total_amount,
          'billing' AS addr_type
   FROM web_sales ws
   JOIN customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE ws.ws_quantity > 30
     AND ws.ws_net_paid_inc_tax > 100
   GROUP BY ca.ca_city
),
shipped AS (
   SELECT ca.ca_city AS city,
          SUM(ws.ws_net_paid_inc_tax) AS total_amount,
          'shipping' AS addr_type
   FROM web_sales ws
   JOIN customer_address ca
     ON ws.ws_ship_addr_sk = ca.ca_address_sk
   WHERE ws.ws_quantity > 30
     AND ws.ws_net_paid_inc_tax > 100
   GROUP BY ca.ca_city
)
SELECT city, total_amount, addr_type
FROM billed
UNION ALL
SELECT city, total_amount, addr_type
FROM shipped
ORDER BY total_amount DESC
LIMIT 100
