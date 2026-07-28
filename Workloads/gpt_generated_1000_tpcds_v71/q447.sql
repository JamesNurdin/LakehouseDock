WITH filtered_dates AS (
    SELECT
        d_date_sk,
        d_year,
        d_quarter_seq,
        d_month_seq,
        d_holiday
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
      AND d_quarter_seq IN (1, 2, 6)
      AND d_holiday = 'N'
)
SELECT
    cp.cp_department,
    cp.cp_type,
    COUNT(DISTINCT cp.cp_catalog_page_sk)               AS page_count,
    MIN(cp.cp_catalog_number)                           AS min_catalog_number,
    MAX(cp.cp_catalog_page_number)                      AS max_page_number,
    AVG(fd_end.d_month_seq)                             AS avg_month_seq,
    SUM(CASE WHEN fd_end.d_holiday = 'N' THEN 1 ELSE 0 END) AS non_holiday_days
FROM catalog_page cp
LEFT OUTER JOIN filtered_dates fd_start
      ON cp.cp_start_date_sk = fd_start.d_date_sk
INNER JOIN filtered_dates fd_end
      ON cp.cp_end_date_sk = fd_end.d_date_sk
WHERE cp.cp_department = 'DEPARTMENT'
  AND cp.cp_type IN ('monthly', 'quarterly')
  AND cp.cp_end_date_sk IN (2451543, 2451084, 2451361)
  AND cp.cp_catalog_number BETWEEN 100 AND 500
  AND fd_end.d_month_seq BETWEEN 3 AND 9
  AND EXISTS (
        SELECT 1
        FROM date_dim d2
        WHERE d2.d_date_sk = cp.cp_start_date_sk
          AND d2.d_year = 2001
    )
GROUP BY cp.cp_department, cp.cp_type
ORDER BY page_count DESC
LIMIT 100
