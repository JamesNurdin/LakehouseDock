SELECT
    wp.wp_url,
    wp.wp_image_count,
    COUNT(DISTINCT wr.wr_reason_sk) AS distinct_return_reasons,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_ship_cost) AS avg_ship_cost
FROM web_returns wr
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_image_count >= 4
  AND wr.wr_return_ship_cost > 500
GROUP BY wp.wp_url, wp.wp_image_count
ORDER BY total_return_amount DESC
LIMIT 100
