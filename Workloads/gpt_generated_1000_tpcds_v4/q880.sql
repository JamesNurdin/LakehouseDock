WITH
  -- Aggregate store and web sales per customer
  customer_sales AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      SUM(ss.ss_net_paid)               AS store_net_paid,
      SUM(ws.ws_net_paid)               AS web_net_paid,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
      COUNT(DISTINCT ws.ws_order_number)  AS web_txn_cnt
    FROM store_sales ss
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    -- current address and demographics of the customer
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    -- web sales for the same customer and time
    JOIN web_sales ws
      ON ws.ws_sold_time_sk = td.t_time_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month IN (1, 4, 11)
      AND td.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_wholesale_cost > 1000
    GROUP BY
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name
  ),
  -- Web‑page and site details for each web sale (one row per sale)
  web_details AS (
    SELECT
      ws.ws_bill_customer_sk          AS cust_sk,
      ws.ws_order_number,
      ws.ws_net_paid,
      wp.wp_url,
      ws.ws_web_site_sk,
      ws.ws_web_page_sk
    FROM web_sales ws
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wp.wp_type = 'content'
  )
SELECT
  cs.c_customer_sk,
  cs.c_first_name,
  cs.c_last_name,
  cs.store_net_paid,
  cs.web_net_paid,
  (cs.store_net_paid + cs.web_net_paid)                     AS total_net_paid,
  r.r_reason_desc,
  wd.wp_url,
  wsite.web_name,
  RANK() OVER (ORDER BY (cs.store_net_paid + cs.web_net_paid) DESC) AS revenue_rank
FROM customer_sales cs
LEFT JOIN store_returns sr
  ON sr.sr_customer_sk = cs.c_customer_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_details wd
  ON wd.cust_sk = cs.c_customer_sk
LEFT JOIN web_site wsite
  ON wd.ws_web_site_sk = wsite.web_site_sk
WHERE r.r_reason_desc IS NOT NULL
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cs.c_customer_sk
          AND ss2.ss_quantity > 5
      )
ORDER BY total_net_paid DESC
LIMIT 100
