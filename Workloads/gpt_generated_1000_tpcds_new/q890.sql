WITH
  -- Aggregate return metrics per catalog page and ship mode
  returns_detail AS (
    SELECT
      cr_catalog_page_sk,
      cr_ship_mode_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt,
      SUM(cr_return_quantity) AS total_quantity
    FROM catalog_returns
    -- Example regex: keep only amounts that have exactly two decimal places
    WHERE regexp_like(CAST(cr_return_amount AS VARCHAR), '^\\d+\\.\\d{2}$')
    GROUP BY cr_catalog_page_sk, cr_ship_mode_sk
  ),
  -- Extract useful info from catalog_page, including regex and LIKE filters
  page_info AS (
    SELECT
      cp_catalog_page_sk,
      cp_catalog_page_id,
      cp_department,
      cp_type,
      cp_description,
      CASE
        WHEN regexp_like(cp_type, '^type[0-9]+$') THEN regexp_extract(cp_type, '(\\d+)$')
        ELSE NULL
      END AS type_number
    FROM catalog_page
    WHERE cp_description LIKE '%catalog%'
  )
SELECT
  COALESCE(pi.cp_catalog_page_id, CAST(rd.cr_catalog_page_sk AS VARCHAR)) AS page_id,
  pi.cp_department,
  pi.cp_type,
  pi.type_number,
  rd.total_return_amount,
  rd.return_cnt,
  rd.total_quantity,
  sm.sm_carrier,
  -- Correlated scalar subquery: distinct returning customers for the page
  (
    SELECT COUNT(DISTINCT cr_returning_customer_sk)
    FROM catalog_returns cr2
    WHERE cr2.cr_catalog_page_sk = pi.cp_catalog_page_sk
  ) AS distinct_returning_customers,
  ROW_NUMBER() OVER (
    PARTITION BY pi.cp_department
    ORDER BY rd.total_return_amount DESC NULLS LAST
  ) AS dept_rank
FROM returns_detail rd
FULL OUTER JOIN page_info pi
  ON rd.cr_catalog_page_sk = pi.cp_catalog_page_sk
LEFT JOIN ship_mode sm
  ON rd.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE (pi.cp_type IS NOT NULL OR rd.cr_catalog_page_sk IS NOT NULL)
ORDER BY pi.cp_department, dept_rank
