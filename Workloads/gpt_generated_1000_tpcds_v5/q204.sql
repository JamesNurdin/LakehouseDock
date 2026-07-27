SELECT
    wp.wp_web_page_id,
    wp.wp_image_count,
    wr.wr_return_amt,
    wr.wr_fee,
    wr.wr_net_loss
FROM tpcds.web_page AS wp
JOIN tpcds.web_returns AS wr
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_image_count >= 3
  AND wr.wr_fee > 30
ORDER BY wr.wr_return_amt DESC
LIMIT 100
