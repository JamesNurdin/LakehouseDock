SELECT
    cp.cp_catalog_page_id,
    cp.cp_description,
    d.d_date,
    d.d_year,
    cp.cp_type
FROM catalog_page AS cp
JOIN date_dim AS d
    ON cp.cp_start_date_sk = d.d_date_sk
WHERE cp.cp_type = 'quarterly'
  AND d.d_year = 1999
ORDER BY d.d_date
