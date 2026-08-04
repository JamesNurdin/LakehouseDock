WITH
  store_sales_agg AS (
    SELECT
      ss_customer_sk,
      ss_sold_date_sk,
      SUM(ss_net_paid) AS store_net_paid
    FROM tpcds.store_sales
    TABLESAMPLE BERNOULLI (10)
    GROUP BY ss_customer_sk, ss_sold_date_sk
  ),
  web_sales_agg AS (
    SELECT
      ws_bill_customer_sk AS customer_sk,
      ws_sold_date_sk AS sold_date_sk,
      ws_ship_mode_sk,
      SUM(ws_net_paid) AS web_net_paid
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
    GROUP BY ws_bill_customer_sk, ws_sold_date_sk, ws_ship_mode_sk
  ),
  sales_combined AS (
    SELECT
      COALESCE(sa.ss_customer_sk, wa.customer_sk) AS customer_sk,
      COALESCE(sa.ss_sold_date_sk, wa.sold_date_sk) AS sold_date_sk,
      wa.ws_ship_mode_sk,
      sa.store_net_paid,
      wa.web_net_paid
    FROM store_sales_agg sa
    FULL OUTER JOIN web_sales_agg wa
      ON sa.ss_customer_sk = wa.customer_sk
     AND sa.ss_sold_date_sk = wa.sold_date_sk
  ),
  no_sales_customers AS (
    SELECT c_customer_sk FROM tpcds.customer
    EXCEPT SELECT ss_customer_sk FROM tpcds.store_sales
    EXCEPT SELECT ws_bill_customer_sk FROM tpcds.web_sales
  ),
  joined AS (
    SELECT
      sc.customer_sk,
      sc.sold_date_sk,
      sc.ws_ship_mode_sk,
      sc.store_net_paid,
      sc.web_net_paid,
      c.c_salutation,
      d.d_year,
      sm.sm_type,
      sm.sm_code
    FROM sales_combined sc
    LEFT JOIN tpcds.customer c
      ON c.c_customer_sk = sc.customer_sk
    LEFT JOIN tpcds.date_dim d
      ON d.d_date_sk = sc.sold_date_sk
    LEFT JOIN tpcds.ship_mode sm
      ON sm.sm_ship_mode_sk = sc.ws_ship_mode_sk
    WHERE d.d_year = 2002
      AND c.c_salutation = 'Mrs.'
      AND sm.sm_code = 'AIR'
      AND (sc.store_net_paid > 1000 OR sc.store_net_paid IS NULL)
      AND (sc.web_net_paid > 500 OR sc.web_net_paid IS NULL)
  )
SELECT
  COALESCE(joined.d_year, -1)                     AS year,
  COALESCE(joined.sm_type, 'ALL')                AS ship_type,
  COALESCE(joined.c_salutation, 'ALL')           AS salutation,
  SUM(COALESCE(joined.store_net_paid, 0) + COALESCE(joined.web_net_paid, 0)) AS total_net_paid,
  ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(joined.store_net_paid, 0) + COALESCE(joined.web_net_paid, 0)) DESC) AS rn,
  (SELECT COUNT(*) FROM no_sales_customers)    AS customers_without_sales
FROM joined
GROUP BY ROLLUP (joined.d_year, joined.sm_type, joined.c_salutation)
HAVING SUM(COALESCE(joined.store_net_paid, 0) + COALESCE(joined.web_net_paid, 0)) > 0
ORDER BY total_net_paid DESC
LIMIT 100
