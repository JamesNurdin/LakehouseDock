WITH
  sub1 AS (
    SELECT
      cc.cc_company,
      cc.cc_company_name,
      cp.cp_catalog_page_id,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_tax) AS total_return_tax,
      COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_company = 1
      AND cc.cc_class = 'large'
      AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451100
      AND cr.cr_fee > 20
      AND cr.cr_return_amount > 0
    GROUP BY cc.cc_company, cc.cc_company_name, cp.cp_catalog_page_id
  ),
  sub2 AS (
    SELECT
      cc.cc_company,
      cc.cc_company_name,
      cp.cp_catalog_page_id,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_tax) AS total_return_tax,
      COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_company = 2
      AND cc.cc_class = 'medium'
      AND cp.cp_end_date_sk BETWEEN 2451000 AND 2451200
      AND cr.cr_fee BETWEEN 10 AND 30
      AND cr.cr_return_quantity >= 1
    GROUP BY cc.cc_company, cc.cc_company_name, cp.cp_catalog_page_id
  ),
  combined AS (
    SELECT * FROM sub1
    UNION ALL
    SELECT * FROM sub2
  )
SELECT
  cc_company,
  cc_company_name,
  cp_catalog_page_id,
  total_return_amount,
  total_return_tax,
  return_cnt,
  SUM(total_return_amount) OVER (
    PARTITION BY cc_company
    ORDER BY total_return_amount DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_return_amount,
  RANK() OVER (
    PARTITION BY cc_company
    ORDER BY total_return_amount DESC
  ) AS amount_rank,
  CASE
    WHEN total_return_amount > 1000 THEN 'High'
    WHEN total_return_amount > 500 THEN 'Medium'
    ELSE 'Low'
  END AS amount_category
FROM combined
ORDER BY cc_company, amount_rank
