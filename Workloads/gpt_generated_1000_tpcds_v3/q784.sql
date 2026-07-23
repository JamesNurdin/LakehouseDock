WITH filtered AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_city,
    cc.cc_state,
    cc.cc_street_name,
    cp.cp_catalog_page_sk,
    cp.cp_type,
    cp.cp_description,
    cr.cr_return_amount AS return_amount,
    cr.cr_return_tax AS return_tax,
    cr.cr_order_number AS order_number,
    regexp_extract(cp.cp_description, '\\d+') AS extracted_number,
    concat(cc.cc_city, ', ', cc.cc_state) AS location
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE regexp_like(cc.cc_street_name, '(Lakeview|Jefferson)')
    AND cp.cp_type LIKE 'monthly%'
    AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451500
)
SELECT
  location,
  extracted_number,
  cp_type,
  COUNT(DISTINCT order_number) AS distinct_orders,
  SUM(return_amount) AS total_return_amount,
  SUM(return_tax) AS total_return_tax,
  AVG(return_tax) AS avg_return_tax
FROM filtered
GROUP BY location, extracted_number, cp_type
ORDER BY total_return_amount DESC
LIMIT 20
