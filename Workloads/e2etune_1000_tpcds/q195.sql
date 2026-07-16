SELECT
    cp.cp_department AS department,
    ws.web_name AS website,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_pages,
    AVG(cp.cp_catalog_page_number) AS avg_page_number,
    MIN(cp.cp_start_date_sk) AS min_start_date_sk,
    MAX(cp.cp_end_date_sk) AS max_end_date_sk
FROM catalog_page cp
JOIN customer c
    ON cp.cp_start_date_sk = c.c_first_sales_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = cp.cp_start_date_sk
JOIN reason r
    ON cp.cp_catalog_page_sk = r.r_reason_sk
WHERE cp.cp_catalog_page_number IN (1, 2, 3, 5, 6)
  AND cp.cp_department = 'DEPARTMENT'
  AND ws.web_state = 'CA'
GROUP BY cp.cp_department, ws.web_name
HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) >= 5
ORDER BY num_customers DESC, avg_page_number ASC
LIMIT 100
