SELECT
  wp.wp_type,
  wp.wp_web_page_id,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_net_loss) AS total_net_loss,
  AVG(wr.wr_return_quantity) AS avg_return_quantity,
  COUNT(*) AS return_count
FROM tpcds.web_returns wr
JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_type IN ('ad', 'welcome')
  AND wr.wr_refunded_hdemo_sk IN (5900, 4645)
  AND wr.wr_return_quantity > 0
GROUP BY wp.wp_type, wp.wp_web_page_id
ORDER BY total_return_amount DESC
