SELECT
    wp.wp_web_page_id,
    wp.wp_type,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_qty
FROM tpcds.web_returns wr
JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_rec_end_date = DATE '2001-09-02'
  AND wr.wr_returned_time_sk = 73981
GROUP BY wp.wp_web_page_id, wp.wp_type
ORDER BY total_return_amount DESC
LIMIT 10
