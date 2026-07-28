SELECT
  wp.wp_url,
  wp.wp_type,
  SUM(wr.wr_return_amt) AS total_return_amt,
  COUNT(*) AS return_count
FROM web_page wp
JOIN web_returns wr
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_char_count > 2000
  AND wr.wr_return_amt > 500
  AND wp.wp_rec_start_date >= DATE '2000-01-01'
GROUP BY wp.wp_url, wp.wp_type
ORDER BY total_return_amt DESC
LIMIT 100
