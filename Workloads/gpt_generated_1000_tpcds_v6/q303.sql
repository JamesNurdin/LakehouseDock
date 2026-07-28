WITH filtered AS (
  SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_description,
    cr.cr_return_amt_inc_tax,
    cr.cr_return_quantity,
    cr.cr_returned_date_sk
  FROM tpcds.catalog_page cp
  JOIN tpcds.catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE regexp_like(cp.cp_description, '(?i)early|schools')
    AND cp.cp_description LIKE '%sale%'
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
)
SELECT
  f.cp_department,
  CONCAT(f.cp_department, '-', CAST(f.cp_catalog_page_number AS VARCHAR)) AS dept_page_key,
  REGEXP_EXTRACT(f.cp_description, '^(\\w+\\s+\\w+\\s+\\w+)', 1) AS first_three_words,
  COUNT(*) AS return_cnt,
  SUM(f.cr_return_amt_inc_tax) AS total_return_inc_tax,
  AVG(f.cr_return_quantity) AS avg_quantity
FROM filtered f
GROUP BY
  f.cp_department,
  CONCAT(f.cp_department, '-', CAST(f.cp_catalog_page_number AS VARCHAR)),
  REGEXP_EXTRACT(f.cp_description, '^(\\w+\\s+\\w+\\s+\\w+)', 1)
ORDER BY total_return_inc_tax DESC
LIMIT 100
