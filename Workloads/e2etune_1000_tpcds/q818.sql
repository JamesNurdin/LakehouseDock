SELECT ca.ca_state,
       r.r_reason_desc,
       COUNT(*) AS address_reason_count,
       AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
       MIN(ca.ca_zip) AS min_zip,
       MAX(ca.ca_zip) AS max_zip
FROM customer_address ca
JOIN reason r
  ON substring(ca.ca_zip, 1, 1) = substring(r.r_reason_id, 1, 1)
WHERE ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
  AND ca.ca_location_type IN ('condo', 'apartment')
  AND r.r_reason_desc IS NOT NULL
GROUP BY ca.ca_state, r.r_reason_desc
HAVING COUNT(*) > 10
ORDER BY address_reason_count DESC
LIMIT 100
