WITH
  store_base AS (
    SELECT
      c.c_customer_id        AS customer_id,
      p.p_promo_name        AS promo_name,
      CAST(NULL AS varchar) AS web_site_name,
      ss.ss_net_paid        AS net_paid,
      ss.ss_ext_discount_amt AS ext_discount_amt,
      ss.ss_ticket_number   AS order_number,
      ss.ss_customer_sk     AS customer_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE c.c_birth_year = 1965
      AND p.p_response_target = 1
      AND ss.ss_sales_price > 30
      AND ss.ss_quantity >= 2
  ),
  web_base AS (
    SELECT
      c.c_customer_id        AS customer_id,
      p.p_promo_name        AS promo_name,
      ws_site.web_name       AS web_site_name,
      ws.ws_net_paid        AS net_paid,
      ws.ws_ext_discount_amt AS ext_discount_amt,
      ws.ws_order_number    AS order_number,
      ws.ws_bill_customer_sk AS customer_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE c.c_birth_country = 'United States'
      AND p.p_channel_tv = 'N'
      AND ws.ws_net_paid > 200
      AND ws.ws_quantity >= 1
      AND ws_site.web_state = 'CA'
  ),
  combined AS (
    SELECT * FROM store_base
    UNION
    SELECT * FROM web_base
  )
SELECT
  cb.customer_id,
  cb.promo_name,
  cb.web_site_name,
  SUM(cb.net_paid)                         AS total_sales,
  AVG(cb.ext_discount_amt)                AS avg_discount,
  COUNT(DISTINCT cb.order_number)          AS order_cnt,
  (SELECT MAX(p2.p_cost) FROM tpcds.promotion p2 WHERE p2.p_channel_tv = 'Y') AS max_tv_promo_cost,
  ROW_NUMBER() OVER (ORDER BY SUM(cb.net_paid) DESC) AS rn,
  lt.cust_total
FROM combined cb
CROSS JOIN LATERAL (
  SELECT SUM(ss2.ss_net_paid) AS cust_total
  FROM tpcds.store_sales ss2
  WHERE ss2.ss_customer_sk = cb.customer_sk
) lt
GROUP BY
  cb.customer_id,
  cb.promo_name,
  cb.web_site_name,
  lt.cust_total
ORDER BY total_sales DESC
LIMIT 100
