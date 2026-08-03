-- goal: Summarize web‑sales revenue and store‑return loss per state and return reason for customers living in cities that start with 'San' and whose email ends with '@example.com', using string functions, IN filtering, a scalar subquery, grouping sets and a CTE.
WITH ws_agg AS (
   SELECT
       ws_bill_customer_sk AS customer_sk,
       ws_bill_addr_sk      AS addr_sk,
       SUM(ws_net_paid)    AS total_ws_paid,
       SUM(ws_net_profit)  AS total_ws_profit
   FROM web_sales
   WHERE regexp_like(CAST(ws_order_number AS VARCHAR), '^[0-9]{9}$')
   GROUP BY ws_bill_customer_sk, ws_bill_addr_sk
),
sr_agg AS (
   SELECT
       sr_customer_sk AS customer_sk,
       sr_addr_sk     AS addr_sk,
       sr_reason_sk   AS reason_sk,
       SUM(sr_refunded_cash) AS total_refunded,
       SUM(sr_net_loss)      AS total_net_loss,
       COUNT(*)              AS return_cnt
   FROM store_returns
   WHERE sr_fee > 50
   GROUP BY sr_customer_sk, sr_addr_sk, sr_reason_sk
)
SELECT
   ca.ca_state,
   r.r_reason_desc,
   MIN(regexp_extract(r.r_reason_id, 'A{5}([A-Z])', 1)) AS reason_code,
   COUNT(DISTINCT c.c_customer_sk)               AS num_customers,
   SUM(COALESCE(ws.total_ws_paid, 0))            AS sum_ws_paid,
   SUM(COALESCE(sr.total_refunded, 0))           AS sum_refunded,
   SUM(COALESCE(sr.total_net_loss, 0))           AS sum_net_loss,
   MIN(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS exemplar_customer_name
FROM customer c
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN ws_agg ws
  ON ws.customer_sk = c.c_customer_sk
 AND ws.addr_sk    = ca.ca_address_sk
LEFT JOIN sr_agg sr
  ON sr.customer_sk = c.c_customer_sk
 AND sr.addr_sk    = ca.ca_address_sk
LEFT JOIN reason r
  ON r.r_reason_sk = sr.reason_sk
WHERE ca.ca_city LIKE 'San%'
  AND regexp_like(c.c_email_address, '@example\\.com$')
  AND c.c_customer_sk IN (
        SELECT sr_customer_sk FROM store_returns WHERE sr_fee > 80
      )
  AND r.r_reason_desc LIKE '%time%'
GROUP BY GROUPING SETS (
   (ca.ca_state, r.r_reason_desc),
   (ca.ca_state),
   (r.r_reason_desc),
   ()
)
ORDER BY ca.ca_state ASC NULLS LAST, r.r_reason_desc ASC NULLS LAST
LIMIT 100
