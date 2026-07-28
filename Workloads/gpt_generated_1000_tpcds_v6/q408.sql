SELECT
    CONCAT(w.w_city, ', ', w.w_state) AS location,
    cp.cp_department,
    regexp_extract(cp.cp_description, '^(\\w+)', 1) AS first_word,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM catalog_returns AS cr
JOIN catalog_page AS cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason AS r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN warehouse AS w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE regexp_like(cp.cp_description, '\\d{2,}')
  AND lower(r.r_reason_desc) LIKE '%did not%'
GROUP BY
    CONCAT(w.w_city, ', ', w.w_state),
    cp.cp_department,
    regexp_extract(cp.cp_description, '^(\\w+)', 1)
HAVING SUM(cr.cr_return_amount) > 1000
   AND COUNT(*) >= 5
ORDER BY total_return_amount DESC
LIMIT 100
