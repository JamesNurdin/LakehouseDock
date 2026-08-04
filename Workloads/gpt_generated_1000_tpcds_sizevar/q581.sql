WITH
  open_dates AS (
    SELECT
      ws.web_site_sk,
      ws.web_name,
      ws.web_open_date_sk,
      ws.web_state,
      ws.web_tax_percentage,
      ws.web_gmt_offset,
      ws.web_company_id,
      d.d_year,
      d.d_month_seq,
      d.d_following_holiday
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND d.d_following_holiday = 'N'
      AND ws.web_state = 'CA'
  ),
  close_dates AS (
    SELECT
      ws.web_site_sk,
      d.d_year AS close_year,
      d.d_month_seq AS close_month_seq
    FROM web_site ws
    JOIN date_dim d ON ws.web_close_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1 AND 12
  ),
  diff_keys AS (
    SELECT web_site_sk FROM web_site WHERE web_open_date_sk IS NOT NULL
    EXCEPT
    SELECT d_date_sk FROM date_dim WHERE d_year = 1999
  )
SELECT
  od.web_name,
  CASE WHEN od.web_open_date_sk IS NOT NULL THEN 'Open' ELSE 'Closed' END AS site_status,
  COUNT(DISTINCT od.web_site_sk) AS site_count,
  SUM(od.web_gmt_offset) AS total_gmt_offset,
  AVG(od.web_tax_percentage) AS avg_tax_pct,
  MIN(od.d_year) AS min_open_year,
  MAX(cd.close_year) AS max_close_year,
  (SELECT MAX(d_date) FROM date_dim) AS max_calendar_date,
  lc.cnt AS sites_per_company
FROM open_dates od
FULL OUTER JOIN close_dates cd ON od.web_site_sk = cd.web_site_sk
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS cnt
  FROM web_site ws2
  WHERE ws2.web_company_id = od.web_company_id
) lc ON TRUE
WHERE EXISTS (SELECT 1 FROM diff_keys dk WHERE dk.web_site_sk = od.web_site_sk)
GROUP BY
  od.web_name,
  CASE WHEN od.web_open_date_sk IS NOT NULL THEN 'Open' ELSE 'Closed' END,
  lc.cnt
ORDER BY total_gmt_offset DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
