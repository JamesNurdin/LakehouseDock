SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    s_tax_percentage
FROM tpcds.store
WHERE s_company_id = 1
  AND s_tax_percentage >= 0.06
  AND s_rec_end_date > DATE '2000-01-01'
ORDER BY s_tax_percentage DESC
LIMIT 100
