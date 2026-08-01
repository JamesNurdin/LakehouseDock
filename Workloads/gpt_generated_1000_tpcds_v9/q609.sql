SELECT
    c.c_customer_id AS customer_id,
    c.c_salutation,
    i.i_category,
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(sr.sr_return_amt) AS store_return_total,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    SUM(wr.wr_return_amt) AS web_return_total,
    SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amt
FROM tpcds.store_returns sr
JOIN tpcds.item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.customer c
  ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.web_returns wr
  ON i.i_item_sk = wr.wr_item_sk
  AND r.r_reason_sk = wr.wr_reason_sk
LEFT JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
  AND wp.wp_customer_sk = c.c_customer_sk
WHERE r.r_reason_desc = 'Did not like the warranty'
  AND i.i_manufact_id = 214
  AND i.i_container = 'Unknown'
  AND c.c_salutation = 'Mr.'
  AND i.i_rec_end_date = DATE '2000-10-26'
GROUP BY c.c_customer_id,
         c.c_salutation,
         i.i_category,
         r.r_reason_desc
ORDER BY total_return_amt DESC
