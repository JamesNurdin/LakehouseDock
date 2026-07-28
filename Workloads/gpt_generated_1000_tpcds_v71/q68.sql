SELECT
  c.c_customer_id,
  concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
  regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS email_user,
  sm.sm_code,
  cp.cp_type,
  sum(ws.ws_net_profit) AS total_net_profit,
  count(*) AS order_count
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  AND cp.cp_description LIKE '%sale%'
  AND NOT EXISTS (
    SELECT 1
    FROM web_sales ws2
    JOIN ship_mode sm2 ON ws2.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    WHERE ws2.ws_bill_customer_sk = ws.ws_bill_customer_sk
      AND regexp_like(sm2.sm_contract, 'GNJ')
  )
GROUP BY
  c.c_customer_id,
  concat(c.c_first_name, ' ', c.c_last_name),
  regexp_extract(c.c_email_address, '^([^@]+)@', 1),
  sm.sm_code,
  cp.cp_type
ORDER BY total_net_profit DESC
LIMIT 100
