WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cp.cp_department,
        cp.cp_type,
        d.d_year,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cp.cp_description
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE regexp_like(cp.cp_description, '\\d{3,}')
      AND c.c_email_address LIKE '%@example.com'
      AND substring(c.c_first_name, 1, 1) = 'A'
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_returning_customer_sk = c.c_customer_sk
      )
)
SELECT
    fr.cp_department,
    fr.d_year,
    fr.cp_type,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count,
    MIN(regexp_extract(fr.cp_description, '(\\d{3,})', 1)) AS sample_code,
    CONCAT(fr.c_first_name, ' ', fr.c_last_name) AS full_name
FROM filtered_returns fr
GROUP BY
    fr.cp_department,
    fr.d_year,
    fr.cp_type,
    fr.c_first_name,
    fr.c_last_name
ORDER BY total_return_amount DESC
LIMIT 100
