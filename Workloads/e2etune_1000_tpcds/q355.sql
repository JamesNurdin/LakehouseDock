SELECT
    cp.cp_department,
    cp.cp_type,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS page_count,
    AVG(cp.cp_catalog_number) AS avg_catalog_number,
    COUNT(DISTINCT ca.ca_address_id) AS address_count,
    AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
    r.r_reason_desc,
    COUNT(*) AS combined_rows
FROM catalog_page cp
JOIN reason r
  ON (cp.cp_catalog_number % 5) = (r.r_reason_sk % 5)
JOIN customer_address ca
  ON (cp.cp_start_date_sk % 1000) = (ca.ca_address_sk % 1000)
WHERE cp.cp_type = 'monthly'
  AND cp.cp_department = 'DEPARTMENT'
  AND ca.ca_country = 'United States'
GROUP BY cp.cp_department, cp.cp_type, r.r_reason_desc
HAVING COUNT(*) > 10
ORDER BY page_count DESC, avg_gmt_offset ASC
LIMIT 200
