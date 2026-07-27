WITH cp_dates AS (
  SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cp.cp_start_date_sk,
    d_start.d_year,
    d_start.d_month_seq,
    d_start.d_date
  FROM catalog_page cp
  JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
  WHERE cp.cp_department = 'Books'
    AND cp.cp_type = 'A'
    AND d_start.d_year = 2001
)
SELECT
  cp_dates.cp_department,
  cp_dates.cp_type,
  cp_dates.d_year,
  COUNT(*) AS page_cnt,
  SUM(cp_dates.cp_catalog_number) AS total_catalog_number,
  AVG(cp_dates.cp_catalog_page_number) AS avg_page_number,
  MAX(cp_dates.cp_catalog_page_number) AS max_page_number,
  CASE
    WHEN cp_dates.cp_type = 'A' THEN 'Type A'
    WHEN cp_dates.cp_type = 'B' THEN 'Type B'
    ELSE 'Other'
  END AS type_label,
  ROW_NUMBER() OVER (PARTITION BY cp_dates.cp_department ORDER BY COUNT(*) DESC) AS dept_rank
FROM cp_dates
WHERE EXISTS (
  SELECT 1
  FROM web_site ws
  WHERE ws.web_open_date_sk = cp_dates.cp_start_date_sk
    AND ws.web_mkt_desc LIKE '%technical%'
    AND ws.web_country = 'United States'
)
GROUP BY
  cp_dates.cp_department,
  cp_dates.cp_type,
  cp_dates.d_year,
  CASE
    WHEN cp_dates.cp_type = 'A' THEN 'Type A'
    WHEN cp_dates.cp_type = 'B' THEN 'Type B'
    ELSE 'Other'
  END
ORDER BY page_cnt DESC
LIMIT 100
