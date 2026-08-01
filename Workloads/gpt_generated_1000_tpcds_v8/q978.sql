WITH
 catalog_sales_filtered AS (
   SELECT
     cs.cs_sold_date_sk,
     d.d_year,
     d.d_month_seq,
     sm.sm_carrier,
     cs.cs_net_profit,
     cs.cs_order_number,
     cs.cs_item_sk,
     regexp_extract(c.c_email_address, '(\\d+)', 1) AS email_digits
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE regexp_like(c.c_email_address, '\\d{3,}')
     AND c.c_last_name LIKE 'G%'
 ),
 web_sales_filtered AS (
   SELECT
     ws.ws_sold_date_sk,
     d.d_year,
     d.d_month_seq,
     sm.sm_carrier,
     ws.ws_net_profit,
     ws.ws_order_number AS cs_order_number,
     ws.ws_item_sk AS cs_item_sk,
     regexp_extract(c.c_email_address, '(\\d+)', 1) AS email_digits
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE regexp_like(c.c_email_address, '\\d{3,}')
     AND c.c_last_name LIKE 'G%'
 ),
 union_sales_main AS (
   SELECT d_year,
          d_month_seq,
          sm_carrier,
          cs.cs_net_profit        AS net_profit,
          cs.cs_order_number,
          cs.cs_item_sk,
          cs.email_digits
   FROM catalog_sales_filtered cs
   UNION
   SELECT d_year,
          d_month_seq,
          sm_carrier,
          ws.ws_net_profit        AS net_profit,
          cs_order_number,
          cs_item_sk,
          email_digits
   FROM web_sales_filtered ws
 ),
 store_customer_full AS (
   SELECT
     COALESCE(ss.ss_sold_date_sk, 0) AS sold_date_sk,
     COALESCE(d.d_year, 0)          AS d_year,
     COALESCE(d.d_month_seq, 0)    AS d_month_seq,
     ss.ss_net_profit,
     ss.ss_customer_sk               AS cs_order_number,
     ss.ss_item_sk                   AS cs_item_sk,
     ''                              AS email_digits,
     CAST(NULL AS varchar)           AS sm_carrier
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   FULL OUTER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
 ),
 full_sales AS (
   SELECT d_year,
          d_month_seq,
          sm_carrier,
          ss_net_profit AS net_profit,
          cs_order_number,
          cs_item_sk,
          email_digits
   FROM store_customer_full
 ),
 all_sales AS (
   SELECT d_year,
          d_month_seq,
          sm_carrier,
          net_profit,
          cs_order_number,
          cs_item_sk,
          email_digits
   FROM union_sales_main
   UNION
   SELECT d_year,
          d_month_seq,
          sm_carrier,
          net_profit,
          cs_order_number,
          cs_item_sk,
          email_digits
   FROM full_sales
 ),
 catalog_only_orders AS (
   SELECT cs_order_number
   FROM catalog_sales
   WHERE cs_order_number IS NOT NULL
   EXCEPT
   SELECT ws_order_number
   FROM web_sales
   WHERE ws_order_number IS NOT NULL
 )
SELECT
  d_year,
  d_month_seq,
  sm_carrier,
  SUM(net_profit)                               AS total_profit,
  COUNT(DISTINCT cs_order_number)               AS distinct_orders,
  MIN(email_digits)                             AS sample_digit,
  CASE
    WHEN SUM(net_profit) > 100000 THEN 'HIGH'
    ELSE 'NORMAL'
  END                                           AS profit_category,
  (SELECT COUNT(*) FROM catalog_only_orders)    AS catalog_only_order_cnt
FROM all_sales
WHERE cs_order_number IS NOT NULL
  AND cs_order_number IN (SELECT cs_order_number FROM catalog_sales_filtered)
GROUP BY CUBE (d_year, d_month_seq, sm_carrier)
ORDER BY total_profit DESC
LIMIT 100
