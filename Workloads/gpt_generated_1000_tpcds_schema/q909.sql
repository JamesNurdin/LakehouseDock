/* goal: Identify customers who are high spenders both in store and web channels during business hours, exclude any customers who have made a return, and classify them by purchase frequency. */
WITH
  store_customer_sales AS (
    SELECT
      c.c_customer_id,
      SUM(ss.ss_net_paid) AS store_net_paid,
      CASE WHEN SUM(ss.ss_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS store_spend_category
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND ss.ss_quantity > 1
      AND EXISTS (
            SELECT 1
            FROM tpcds.promotion p
            WHERE p.p_item_sk = ss.ss_item_sk
              AND p.p_discount_active = 'Y'
          )
    GROUP BY c.c_customer_id
  ),
  web_customer_sales AS (
    SELECT
      c.c_customer_id,
      SUM(ws.ws_net_paid) AS web_net_paid,
      CASE WHEN SUM(ws.ws_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS web_spend_category
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND ws.ws_quantity > 1
    GROUP BY c.c_customer_id
  ),
  high_spenders AS (
    SELECT s.c_customer_id
    FROM store_customer_sales s
    WHERE s.store_spend_category = 'High'
    INTERSECT
    SELECT w.c_customer_id
    FROM web_customer_sales w
    WHERE w.web_spend_category = 'High'
  ),
  customers_with_returns AS (
    SELECT DISTINCT c.c_customer_id
    FROM tpcds.store_returns sr
    JOIN tpcds.customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    UNION
    SELECT DISTINCT c.c_customer_id
    FROM tpcds.web_returns wr
    JOIN tpcds.customer c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
  ),
  filtered_customers AS (
    SELECT hs.c_customer_id
    FROM high_spenders hs
    EXCEPT
    SELECT c.c_customer_id
    FROM customers_with_returns c
  )
SELECT
  fc.c_customer_id,
  CASE
    WHEN (
      SELECT COUNT(*)
      FROM tpcds.store_sales ss3
      WHERE ss3.ss_customer_sk = cust.c_customer_sk
    ) > 5 THEN 'Frequent'
    ELSE 'Infrequent'
  END AS purchase_frequency
FROM filtered_customers fc
JOIN tpcds.customer cust
  ON fc.c_customer_id = cust.c_customer_id
ORDER BY purchase_frequency DESC, fc.c_customer_id
LIMIT 100
