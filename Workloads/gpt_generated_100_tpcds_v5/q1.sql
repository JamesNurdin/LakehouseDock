SELECT
  wr_web_page_sk,
  COUNT(*) AS returns_cnt,
  SUM(wr_net_loss) AS total_loss
FROM tpcds.web_returns
WHERE wr_web_page_sk IN (2326, 14)
  AND wr_return_quantity > 1
GROUP BY wr_web_page_sk
ORDER BY total_loss DESC
LIMIT 100
