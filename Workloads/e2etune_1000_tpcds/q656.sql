SELECT
    sr.sr_returned_date_sk AS return_date_sk,
    COUNT(DISTINCT sr.sr_item_sk) AS store_item_cnt,
    COUNT(DISTINCT wr.wr_item_sk) AS web_item_cnt,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(sr.sr_return_tax) AS store_tax_total,
    SUM(wr.wr_return_tax) AS web_tax_total,
    (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    (SUM(sr.sr_return_tax) + SUM(wr.wr_return_tax)) / (SUM(sr.sr_return_quantity) + SUM(wr.wr_return_quantity)) AS avg_tax_per_item
FROM store_returns sr
JOIN web_returns wr
  ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
WHERE sr.sr_return_tax > 50
  AND wr.wr_return_tax > 50
  AND sr.sr_return_quantity > 0
  AND wr.wr_return_quantity > 0
GROUP BY sr.sr_returned_date_sk
HAVING (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 1000
ORDER BY total_net_loss DESC
LIMIT 20
