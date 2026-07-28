WITH
  returns_agg AS (
    SELECT
      'catalog_return' AS source,
      cp.cp_department AS category,
      SUM(cr.cr_return_amt_inc_tax) AS total_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND c.c_birth_day = 13
    GROUP BY cp.cp_department
  ),
  web_sales_agg AS (
    SELECT
      'web_sale' AS source,
      ws_site.web_city AS category,
      SUM(ws.ws_net_paid_inc_tax) AS total_amount
    FROM tpcds.web_sales ws
    JOIN tpcds.web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN tpcds.customer c2
      ON ws.ws_bill_customer_sk = c2.c_customer_sk
    WHERE ws_site.web_city = 'Pleasant Hill'
      AND c2.c_current_hdemo_sk = 1461
    GROUP BY ws_site.web_city
  )
SELECT
  source,
  category,
  total_amount
FROM returns_agg
UNION ALL
SELECT
  source,
  category,
  total_amount
FROM web_sales_agg
ORDER BY total_amount DESC
LIMIT 20
