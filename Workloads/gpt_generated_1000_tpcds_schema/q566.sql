WITH
  -- Full outer join of store sales and returns, keeping all records from both sides
  joined_sales AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_customer_sk,
      ss.ss_item_sk,
      ss.ss_net_paid,
      sr.sr_return_quantity,
      -- Correlated scalar subquery: total number of web sales for the same customer
      (SELECT COUNT(*)
         FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = ss.ss_customer_sk) AS web_sales_cnt
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE ss.ss_net_paid > 1000
  ),
  -- Customers who bought from the store channel (with a high spend)
  customers_store AS (
    SELECT DISTINCT c.c_customer_id AS c_id
    FROM joined_sales js
    JOIN customer c
      ON js.ss_customer_sk = c.c_customer_sk
    WHERE js.ss_net_paid > 2000
  ),
  -- Customers who bought from the web channel (with a high spend)
  customers_web AS (
    SELECT DISTINCT c.c_customer_id AS c_id
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_net_paid > 1500
  ),
  -- Customers appearing in both store and web high‑spend sets
  intersect_customers AS (
    SELECT c_id FROM customers_store
    INTERSECT
    SELECT c_id FROM customers_web
  ),
  -- Customers who appear in store high‑spend set but NOT in any catalog return
  customers_with_catalog_returns AS (
    SELECT DISTINCT c.c_customer_id AS c_id
    FROM catalog_returns cr
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
  ),
  except_customers AS (
    SELECT c_id FROM customers_store
    EXCEPT
    SELECT c_id FROM customers_with_catalog_returns
  )
SELECT
  ic.c_id        AS customer_id,
  'BothChannels' AS channel_type,
  (SELECT COUNT(*)
     FROM store_sales ss2
    WHERE ss2.ss_customer_sk = c.c_customer_sk) AS store_purchase_count
FROM intersect_customers ic
JOIN customer c
  ON ic.c_id = c.c_customer_id
UNION ALL
SELECT
  ec.c_id        AS customer_id,
  'StoreOnly'    AS channel_type,
  (SELECT COUNT(*)
     FROM store_sales ss2
    WHERE ss2.ss_customer_sk = c.c_customer_sk) AS store_purchase_count
FROM except_customers ec
JOIN customer c
  ON ec.c_id = c.c_customer_id
ORDER BY customer_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
