WITH
  base AS (
    SELECT
      ss.ss_sold_date_sk,
      sr.sr_returned_date_sk,
      c.c_customer_id,
      c.c_birth_country,
      ca.ca_state,
      ss.ss_quantity,
      ss.ss_net_paid,
      sr.sr_return_amt,
      sr.sr_fee
    FROM store_sales ss
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
     AND sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
     AND sr.sr_addr_sk = ca.ca_address_sk
    WHERE
      ss.ss_quantity > 20
      AND ss.ss_sold_date_sk BETWEEN 2451500 AND 2452000
      AND sr.sr_fee > 20
      AND sr.sr_returned_date_sk = 2451822
      AND c.c_birth_country IN ('GAMBIA', 'UKRAINE', 'BURKINA FASO')
      AND ca.ca_gmt_offset BETWEEN -5.00 AND -4.00
  ),

  sales_summary AS (
    SELECT
      c_customer_id,
      c_birth_country,
      ca_state,
      ss_sold_date_sk AS activity_date,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(ss_quantity) AS total_quantity,
      COUNT(*) AS cnt_sales
    FROM base
    GROUP BY c_customer_id, c_birth_country, ca_state, ss_sold_date_sk
  ),

  returns_summary AS (
    SELECT
      c_customer_id,
      ca_state,
      sr_returned_date_sk AS activity_date,
      SUM(sr_return_amt) AS total_return_amt,
      SUM(sr_fee) AS total_fee,
      COUNT(*) AS cnt_returns
    FROM base
    GROUP BY c_customer_id, ca_state, sr_returned_date_sk
  ),

  union_set AS (
    SELECT
      s.c_customer_id,
      s.c_birth_country,
      s.ca_state,
      s.activity_date,
      s.total_net_paid,
      0.0 AS total_return_amt,
      RANK() OVER (PARTITION BY s.ca_state ORDER BY s.total_net_paid DESC) AS rank_in_state
    FROM sales_summary s
    WHERE s.total_net_paid > (SELECT AVG(total_net_paid) FROM sales_summary)
    UNION ALL
    SELECT
      r.c_customer_id,
      NULL AS c_birth_country,
      r.ca_state,
      r.activity_date,
      0.0 AS total_net_paid,
      r.total_return_amt,
      RANK() OVER (PARTITION BY r.ca_state ORDER BY r.total_return_amt DESC) AS rank_in_state
    FROM returns_summary r
    WHERE r.total_return_amt > (SELECT AVG(total_return_amt) FROM returns_summary)
  )
SELECT
  u.c_customer_id,
  u.c_birth_country,
  u.ca_state,
  u.activity_date,
  u.total_net_paid,
  u.total_return_amt,
  u.rank_in_state,
  (SELECT MAX(ss_sold_date_sk) FROM store_sales) AS max_sold_date_sk
FROM union_set u
WHERE u.activity_date BETWEEN 2451500 AND 2452000
ORDER BY u.rank_in_state
LIMIT 100
