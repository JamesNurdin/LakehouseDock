SELECT
  i.i_item_id,
  i.i_category,
  i.i_brand,
  COUNT(DISTINCT ss.ss_ticket_number) AS cnt_tickets,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  AVG(sr.sr_fee) AS avg_return_fee,
  SUM(sr.sr_net_loss) AS total_return_loss,
  AVG(wr.wr_return_amt) AS avg_web_return_amt,
  (SELECT COUNT(*) FROM tpcds.web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk) AS total_web_returns_for_item
FROM tpcds.item i
JOIN tpcds.store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_category_id = 4
  AND i.i_wholesale_cost > 7.00
  AND ss.ss_sales_price BETWEEN 10 AND 70
GROUP BY
  i.i_item_id,
  i.i_category,
  i.i_brand,
  i.i_item_sk
ORDER BY total_sales DESC
LIMIT 100
