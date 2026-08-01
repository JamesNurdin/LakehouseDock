WITH
  customer_sales AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
      COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
      MAX(ss.ss_net_paid) AS max_store_net_paid,
      MAX(ws.ws_net_paid) AS max_web_net_paid
    FROM customer c
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
  ),
  intersect_customers AS (
    SELECT sr.sr_customer_sk AS cust_sk FROM store_returns sr
    INTERSECT
    SELECT ws.ws_bill_customer_sk AS cust_sk FROM web_sales ws
  )
SELECT *
FROM (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    ss.ss_ticket_number AS txn_id,
    ss.ss_ext_sales_price AS store_sales_amt,
    ws.ws_ext_sales_price AS web_sales_amt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_net_paid DESC) AS rn,
    cs.store_sales_amount,
    cs.web_sales_amount,
    (SELECT MAX(ss2.ss_ext_sales_price) FROM store_sales ss2) AS max_store_sales_amount
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN store_returns sr_item ON sr_item.sr_item_sk = ss.ss_item_sk
  JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_sales ws_ship ON ws_ship.ws_ship_customer_sk = c.c_customer_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
  JOIN warehouse wh2 ON ws_ship.ws_warehouse_sk = wh2.w_warehouse_sk
  LEFT JOIN customer_sales cs ON cs.c_customer_sk = c.c_customer_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_customer_sk NOT IN (
      SELECT sr2.sr_customer_sk FROM store_returns sr2 WHERE sr2.sr_return_amt > 5000
    )
  UNION DISTINCT
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    ws.ws_order_number AS txn_id,
    ss.ss_ext_sales_price AS store_sales_amt,
    ws.ws_ext_sales_price AS web_sales_amt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_paid DESC) AS rn,
    cs.store_sales_amount,
    cs.web_sales_amount,
    (SELECT MAX(ss2.ss_ext_sales_price) FROM store_sales ss2) AS max_store_sales_amount
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_sales ws_ship ON ws_ship.ws_ship_customer_sk = c.c_customer_sk
  JOIN web_site wsite2 ON ws.ws_web_site_sk = wsite2.web_site_sk
  JOIN warehouse wh3 ON ws.ws_warehouse_sk = wh3.w_warehouse_sk
  JOIN warehouse wh4 ON ws_ship.ws_warehouse_sk = wh4.w_warehouse_sk
  JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store_returns sr2 ON sr2.sr_ticket_number = ss.ss_ticket_number
  JOIN store_returns sr_item2 ON sr_item2.sr_item_sk = ss.ss_item_sk
  LEFT JOIN customer_sales cs ON cs.c_customer_sk = c.c_customer_sk
  WHERE c.c_preferred_cust_flag = 'N'
    AND c.c_customer_sk NOT IN (
      SELECT sr3.sr_customer_sk FROM store_returns sr3 WHERE sr3.sr_return_amt > 5000
    )
) AS combined
JOIN intersect_customers ic ON ic.cust_sk = combined.c_customer_sk
FULL OUTER JOIN (
  SELECT c.c_customer_sk, c.c_email_address
  FROM customer c
  WHERE c.c_birth_year = 1975
) AS birth1975 ON birth1975.c_customer_sk = combined.c_customer_sk
ORDER BY combined.c_customer_id
LIMIT 100
