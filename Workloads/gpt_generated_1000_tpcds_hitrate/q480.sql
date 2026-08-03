SELECT
  cp.cp_catalog_page_id,
  SUM(cs.cs_net_paid_inc_tax) AS total_paid_inc_tax
FROM
  catalog_page cp
JOIN
  catalog_sales cs
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
  cp.cp_catalog_page_number = 7
  AND cs.cs_net_paid_inc_tax > 500.00
GROUP BY
  cp.cp_catalog_page_id
ORDER BY
  total_paid_inc_tax DESC
LIMIT 10
