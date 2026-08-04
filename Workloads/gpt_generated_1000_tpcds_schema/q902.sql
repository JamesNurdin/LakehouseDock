WITH intersect_customers AS (
  SELECT cr.cr_returning_customer_sk AS cust_sk
  FROM catalog_returns cr
  WHERE regexp_like(CAST(cr.cr_returning_hdemo_sk AS varchar), '^[0-9]{4}$')
  INTERSECT
  SELECT c.c_customer_sk AS cust_sk
  FROM customer c
  WHERE c.c_last_name LIKE '%son'
    AND regexp_like(c.c_first_name, '^A.*')
),

sales_with_cc AS (
  SELECT
    ss.ss_customer_sk,
    ss.ss_sold_date_sk,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    d.d_year,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_county,
    cc.cc_city
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE ss.ss_ext_sales_price > 1000
),

sales_enhanced AS (
  SELECT
    swc.*,
    CONCAT(swc.c_first_name, ' ', swc.c_last_name) AS full_name,
    l.email_domain
  FROM sales_with_cc swc
  CROSS JOIN LATERAL (
    SELECT regexp_extract(swc.c_email_address, '@([^.]*)\\.', 1) AS email_domain
  ) l
  WHERE swc.ss_customer_sk IN (SELECT cust_sk FROM intersect_customers)
    AND EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_returning_customer_sk = swc.ss_customer_sk
        AND cr2.cr_returned_date_sk = swc.ss_sold_date_sk
    )
)

SELECT
  cc_name,
  d_year,
  SUM(total_profit) AS agg_profit,
  SUM(txn_cnt) AS agg_txn_cnt
FROM (
  SELECT
    se.cc_name,
    se.d_year,
    se.ss_net_profit AS total_profit,
    1 AS txn_cnt
  FROM sales_enhanced se
  WHERE se.cc_county LIKE '%County'
  UNION DISTINCT
  SELECT
    se.cc_name,
    se.d_year,
    se.ss_net_profit AS total_profit,
    1 AS txn_cnt
  FROM sales_enhanced se
  WHERE se.cc_name LIKE 'Call%'
) u
GROUP BY cc_name, d_year
ORDER BY agg_profit DESC
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
