WITH
  store_agg AS (
    SELECT
      d.d_year,
      CASE WHEN regexp_like(cp.cp_description, '(?i)season') THEN 'Seasonal' ELSE 'Regular' END AS page_category,
      SUM(ss.ss_ext_sales_price) AS store_sales_total,
      SUM(ss.ss_net_paid) AS store_net_total
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND cp.cp_type LIKE 'C%'
    GROUP BY d.d_year,
      CASE WHEN regexp_like(cp.cp_description, '(?i)season') THEN 'Seasonal' ELSE 'Regular' END
  ),
  web_agg AS (
    SELECT
      d.d_year,
      CASE WHEN regexp_like(cp.cp_description, '(?i)season') THEN 'Seasonal' ELSE 'Regular' END AS page_category,
      SUM(ws.ws_ext_sales_price) AS web_sales_total,
      SUM(ws.ws_net_paid) AS web_net_total
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND cp.cp_type LIKE 'C%'
    GROUP BY d.d_year,
      CASE WHEN regexp_like(cp.cp_description, '(?i)season') THEN 'Seasonal' ELSE 'Regular' END
  )
SELECT
  s.d_year,
  s.page_category,
  CONCAT('Year ', CAST(s.d_year AS varchar), ' - ', s.page_category) AS period_category,
  s.store_sales_total,
  w.web_sales_total,
  (COALESCE(s.store_sales_total, 0) + COALESCE(w.web_sales_total, 0)) AS combined_sales,
  CASE
    WHEN COALESCE(s.store_sales_total, 0) > COALESCE(w.web_sales_total, 0) THEN 'Store Higher'
    WHEN COALESCE(s.store_sales_total, 0) < COALESCE(w.web_sales_total, 0) THEN 'Web Higher'
    ELSE 'Equal'
  END AS sales_comparison
FROM store_agg s
FULL OUTER JOIN web_agg w
  ON s.d_year = w.d_year
  AND s.page_category = w.page_category
WHERE s.store_sales_total IS NOT NULL OR w.web_sales_total IS NOT NULL
ORDER BY s.d_year DESC, combined_sales DESC
LIMIT 100
