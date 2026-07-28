WITH returns_by_center AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_manager,
    cc.cc_city,
    CONCAT(cc.cc_manager, ' - ', cc.cc_city) AS manager_city,
    regexp_extract(w.w_suite_number, '\\d+') AS suite_number,
    SUBSTRING(w.w_suite_number FROM 7) AS suite_suffix,
    cp.cp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS total_returns,
    COUNT(*) FILTER (WHERE regexp_like(cc.cc_manager, '^C')) AS manager_c_returns,
    COUNT(*) FILTER (WHERE cp.cp_type LIKE 'monthly%') AS monthly_type_returns
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE regexp_like(cc.cc_manager, '^C')
    AND cc.cc_hours LIKE '%8AM%'
  GROUP BY
    cc.cc_call_center_id,
    cc.cc_manager,
    cc.cc_city,
    CONCAT(cc.cc_manager, ' - ', cc.cc_city),
    regexp_extract(w.w_suite_number, '\\d+'),
    SUBSTRING(w.w_suite_number FROM 7),
    cp.cp_type
)
SELECT
  cc_call_center_id,
  cc_manager,
  cc_city,
  manager_city,
  suite_number,
  suite_suffix,
  cp_type,
  total_return_amount,
  avg_return_amount,
  total_returns,
  manager_c_returns,
  monthly_type_returns,
  SUM(total_return_amount) OVER (
    ORDER BY total_return_amount DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_return_amount
FROM returns_by_center
ORDER BY total_return_amount DESC
LIMIT 100
