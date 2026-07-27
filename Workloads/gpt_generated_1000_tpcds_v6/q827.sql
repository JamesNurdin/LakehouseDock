WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_time_sk,
        cr.cr_reason_sk
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity <= 5
      AND cr.cr_returned_time_sk BETWEEN 10000 AND 50000
)
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    dd.d_year,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_returns fr
JOIN tpcds.catalog_page cp
  ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.date_dim dd
  ON fr.cr_returned_date_sk = dd.d_date_sk
WHERE dd.d_year = 2001
  AND dd.d_month_seq BETWEEN 1 AND 12
  AND cp.cp_department = 'Electronics'
  AND cp.cp_catalog_number BETWEEN 10 AND 50
  AND cp.cp_type = 'Standard'
  AND EXISTS (
        SELECT 1
        FROM tpcds.reason r
        WHERE r.r_reason_sk = fr.cr_reason_sk
          AND r.r_reason_desc LIKE '%warranty%'
    )
GROUP BY cp.cp_department, cp.cp_catalog_number, dd.d_year
ORDER BY total_return_amount DESC
LIMIT 100
