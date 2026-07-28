WITH filtered_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_department,
        cp_catalog_page_number,
        cp_description,
        cp_type
    FROM catalog_page
    WHERE regexp_like(cp_description, '\\d{3}')
      AND cp_type LIKE 'A%'
)
SELECT
    fp.cp_department,
    fp.cp_catalog_page_number,
    d.d_year,
    SUM(r.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    MAX(concat(c.c_first_name, ' ', c.c_last_name)) AS sample_customer_name
FROM filtered_pages fp
JOIN catalog_returns r
  ON r.cr_catalog_page_sk = fp.cp_catalog_page_sk
JOIN date_dim d
  ON r.cr_returned_date_sk = d.d_date_sk
  AND d.d_year = 2022
JOIN customer c
  ON r.cr_refunded_customer_sk = c.c_customer_sk
  AND regexp_like(c.c_email_address, '^.*@example\\.com$')
JOIN customer_address ca
  ON r.cr_refunded_addr_sk = ca.ca_address_sk
  AND ca.ca_city LIKE '%York%'
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns r2
    WHERE r2.cr_order_number = r.cr_order_number
      AND r2.cr_return_amount = 0
)
GROUP BY GROUPING SETS (
    (fp.cp_department, fp.cp_catalog_page_number, d.d_year),
    (fp.cp_department, d.d_year),
    (d.d_year),
    ()
)
ORDER BY total_return_amount DESC NULLS LAST
LIMIT 100
