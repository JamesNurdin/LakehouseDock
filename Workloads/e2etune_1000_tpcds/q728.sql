SELECT
  cr.cr_returned_date_sk AS date_sk,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_store_credit) AS total_store_credit,
  COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
  AVG(cr.cr_fee) AS avg_fee,
  SUM(wp.wp_image_count) AS total_image_count,
  AVG(wp.wp_char_count) AS avg_char_count,
  COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
FROM catalog_returns cr
JOIN web_page wp
  ON cr.cr_returned_date_sk = wp.wp_creation_date_sk
WHERE cr.cr_fee > 20
  AND wp.wp_image_count > 0
GROUP BY cr.cr_returned_date_sk
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 200
