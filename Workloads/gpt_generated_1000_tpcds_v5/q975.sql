WITH
  returns_agg AS (
    SELECT
      d.d_year AS year_int,
      sm.sm_type AS category,
      SUM(cr.cr_return_amount) AS metric,
      CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS flag
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
      AND sm.sm_ship_mode_sk IN (2, 3)
    GROUP BY d.d_year, sm.sm_type
    HAVING SUM(cr.cr_return_amount) > 500
  ),
  web_page_agg AS (
    SELECT
      d_cre.d_year AS year_int,
      NULL AS category,
      CAST(COUNT(DISTINCT wp.wp_web_page_sk) AS decimal(10,2)) AS metric,
      CASE WHEN COUNT(*) > 20 THEN 'ACTIVE' ELSE 'LESS_ACTIVE' END AS flag
    FROM web_page wp
    JOIN date_dim d_cre ON wp.wp_creation_date_sk = d_cre.d_date_sk
    WHERE wp.wp_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
      AND wp.wp_link_count > 15
    GROUP BY d_cre.d_year
    HAVING COUNT(DISTINCT wp.wp_web_page_sk) >= 5
  )
SELECT year_int, category, metric, flag
FROM returns_agg
UNION ALL
SELECT year_int, category, metric, flag
FROM web_page_agg
ORDER BY year_int DESC, metric DESC
LIMIT 100
