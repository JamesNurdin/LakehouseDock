WITH store_agg AS (
   SELECT
      c.c_customer_sk,
      c.c_customer_id,
      CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
      COUNT(ss.ss_ticket_number) AS store_txn_count,
      SUM(ss.ss_net_paid) AS store_net_paid,
      SUM(ss.ss_net_profit) AS store_net_profit,
      CASE WHEN c.c_email_address LIKE '%@gmail.com' THEN 'Gmail' ELSE 'Other' END AS email_provider,
      CASE WHEN ca.ca_location_type = 'apartment' THEN 'Apt' ELSE ca.ca_location_type END AS location_type_clean,
      REGEXP_EXTRACT(ca.ca_county, '(.*) County', 1) AS county_name
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE ca.ca_city LIKE 'San%'
     AND REGEXP_LIKE(ca.ca_county, '.*County')
   GROUP BY
      c.c_customer_sk,
      c.c_customer_id,
      ca.ca_city,
      ca.ca_state,
      c.c_email_address,
      ca.ca_location_type,
      ca.ca_county
),
web_agg AS (
   SELECT
      c.c_customer_sk,
      c.c_customer_id,
      CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
      COUNT(ws.ws_order_number) AS web_txn_count,
      SUM(ws.ws_net_paid) AS web_net_paid,
      SUM(ws.ws_net_profit) AS web_net_profit,
      CASE WHEN c.c_email_address LIKE '%@gmail.com' THEN 'Gmail' ELSE 'Other' END AS email_provider,
      CASE WHEN ca.ca_location_type = 'apartment' THEN 'Apt' ELSE ca.ca_location_type END AS location_type_clean,
      REGEXP_EXTRACT(ca.ca_county, '(.*) County', 1) AS county_name
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE ca.ca_city LIKE 'San%'
     AND REGEXP_LIKE(ca.ca_county, '.*County')
   GROUP BY
      c.c_customer_sk,
      c.c_customer_id,
      ca.ca_city,
      ca.ca_state,
      c.c_email_address,
      ca.ca_location_type,
      ca.ca_county
),
combined AS (
   SELECT
      COALESCE(s.c_customer_sk, w.c_customer_sk) AS customer_sk,
      COALESCE(s.c_customer_id, w.c_customer_id) AS customer_id,
      COALESCE(s.city_state, w.city_state) AS city_state,
      COALESCE(s.email_provider, w.email_provider) AS email_provider,
      COALESCE(s.location_type_clean, w.location_type_clean) AS location_type,
      COALESCE(s.county_name, w.county_name) AS county_name,
      s.store_txn_count,
      w.web_txn_count,
      s.store_net_paid,
      w.web_net_paid,
      s.store_net_profit,
      w.web_net_profit,
      (COALESCE(s.store_txn_count, 0) + COALESCE(w.web_txn_count, 0)) AS total_txn,
      (COALESCE(s.store_net_paid, 0) + COALESCE(w.web_net_paid, 0)) AS total_net_paid,
      (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0)) AS total_net_profit
   FROM store_agg s
   FULL OUTER JOIN web_agg w ON s.c_customer_sk = w.c_customer_sk
)
SELECT
   c.customer_id,
   c.city_state,
   c.email_provider,
   c.location_type,
   c.county_name,
   c.total_txn,
   c.total_net_paid,
   c.total_net_profit,
   CASE
      WHEN c.total_net_profit > 0 THEN 'Profit'
      WHEN c.total_net_profit < 0 THEN 'Loss'
      ELSE 'Break Even'
   END AS profit_status
FROM combined c
WHERE c.total_txn > 0
  AND EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_customer_sk = c.customer_sk
  )
ORDER BY c.total_net_paid DESC
LIMIT 100
