WITH returns_filtered AS (
    SELECT
        cr.cr_return_amount,
        w.w_county,
        cp.cp_department,
        ca.ca_zip,
        ca.ca_suite_number,
        t.t_hour
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(w.w_street_type, '.*way$')
      AND ca.ca_suite_number LIKE 'Suite%'
      AND ca.ca_zip LIKE '1%'
      AND t.t_hour BETWEEN 8 AND 12
)
SELECT
    w_county,
    cp_department,
    REGEXP_EXTRACT(ca_zip, '(\\d{3})') AS zip_prefix,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count
FROM returns_filtered
GROUP BY
    w_county,
    cp_department,
    REGEXP_EXTRACT(ca_zip, '(\\d{3})')
ORDER BY total_return_amount DESC
LIMIT 100
