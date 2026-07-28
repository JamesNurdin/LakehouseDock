WITH returns_year AS (
  SELECT
    d.d_year AS year,
    'return_amount' AS metric_type,
    SUM(cr.cr_return_amount) AS metric_value,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'positive' ELSE 'non_positive' END AS category,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'F'
    AND d.d_year >= 2000
    AND cr.cr_return_amount > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2)
    AND NOT EXISTS (
      SELECT 1 FROM web_page wp
      WHERE wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_max_ad_count > 5
    )
  GROUP BY d.d_year
),
ad_counts_year AS (
  SELECT
    d.d_year AS year,
    'ad_count' AS metric_type,
    SUM(wp.wp_max_ad_count) AS metric_value,
    CASE WHEN SUM(wp.wp_max_ad_count) > 10 THEN 'high' ELSE 'low' END AS category,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(wp.wp_max_ad_count) DESC) AS rn
  FROM web_page wp
  JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
  WHERE d.d_year >= 2000
    AND wp.wp_type IN ('article', 'blog')
    AND wp.wp_customer_sk IN (
      SELECT cr.cr_returning_customer_sk
      FROM catalog_returns cr
      WHERE cr.cr_return_amount > 100
    )
    AND NOT EXISTS (
      SELECT 1 FROM catalog_returns cr
      WHERE cr.cr_returned_date_sk = d.d_date_sk
    )
  GROUP BY d.d_year
)
SELECT year, metric_type, metric_value, category, rn
FROM returns_year
UNION ALL
SELECT year, metric_type, metric_value, category, rn
FROM ad_counts_year
ORDER BY year, metric_type, metric_value DESC
LIMIT 100
