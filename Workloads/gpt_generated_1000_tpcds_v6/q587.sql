WITH date_filter AS (
   SELECT d_date_sk, d_date
   FROM date_dim
   WHERE d_date BETWEEN DATE '2000-09-01' AND DATE '2000-09-30'
)
SELECT
   combined.source,
   combined.category,
   combined.total_amount,
   combined.transaction_count,
   combined.average_amount,
   combined.overall_average_metric
FROM (
   SELECT
      'return' AS source,
      i.i_category AS category,
      SUM(cr.cr_return_amount) AS total_amount,
      COUNT(*) AS transaction_count,
      AVG(cr.cr_return_amount) AS average_amount,
      (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_average_metric
   FROM catalog_returns cr
   JOIN date_filter df ON cr.cr_returned_date_sk = df.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE i.i_category IS NOT NULL
   GROUP BY i.i_category
   HAVING SUM(cr.cr_return_amount) > 1000

   UNION ALL

   SELECT
      'web' AS source,
      wp.wp_type AS category,
      SUM(wp.wp_char_count) AS total_amount,
      COUNT(*) AS transaction_count,
      AVG(wp.wp_char_count) AS average_amount,
      CAST((SELECT AVG(wp2.wp_char_count) FROM web_page wp2) AS decimal(10,2)) AS overall_average_metric
   FROM web_page wp
   JOIN date_filter df ON wp.wp_creation_date_sk = df.d_date_sk
   WHERE wp.wp_autogen_flag = 'N'
   GROUP BY wp.wp_type
   HAVING SUM(wp.wp_char_count) > 500
) AS combined
ORDER BY combined.total_amount DESC
LIMIT 100
