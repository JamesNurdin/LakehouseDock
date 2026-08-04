SELECT
  d.d_year,
  hd.hd_buy_potential,
  wp.wp_type,
  SUM(ss.ss_net_profit) AS total_store_profit,
  SUM(ws.ws_net_profit) AS total_web_profit,
  AVG(sr.sr_return_amt) AS avg_store_return_amt,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
  MAX(wr.wr_fee) AS max_web_return_fee
FROM
  date_dim d
  INNER JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  INNER JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_hdemo_sk = hd.hd_demo_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
  INNER JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  INNER JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wr.wr_order_number = ws.ws_order_number
WHERE
  d.d_year = 2001
  AND hd.hd_income_band_sk = 5
  AND wp.wp_type = 'product'
  AND d.d_date < (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2000)
GROUP BY
  d.d_year,
  hd.hd_buy_potential,
  wp.wp_type
ORDER BY
  total_store_profit DESC,
  total_web_profit DESC
LIMIT 100
