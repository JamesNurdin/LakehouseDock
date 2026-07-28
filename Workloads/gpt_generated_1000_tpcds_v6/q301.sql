SELECT
  cc_call_center_id,
  cc_name,
  cc_city,
  cc_state,
  cc_sq_ft
FROM
  call_center
WHERE
  cc_company = 4
  AND cc_sq_ft > 0
LIMIT 100
