SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  r.r_reason_desc,
  wp.wp_type,
  COUNT(*) AS return_cnt,
  SUM(wr.wr_return_amt) AS total_return_amt,
  AVG(wr.wr_return_tax) AS avg_return_tax,
  MIN(wr.wr_return_ship_cost) AS min_ship_cost,
  MAX(wr.wr_refunded_cash) AS max_refunded_cash
FROM web_returns wr
JOIN customer c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wr.wr_return_ship_cost BETWEEN 200 AND 800
  AND wr.wr_account_credit BETWEEN 20 AND 100
  AND wp.wp_link_count >= 5
  AND wp.wp_rec_end_date = DATE '2000-09-02'
  AND r.r_reason_id = 'AAAAAAAAGAAAAAAA'
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, r.r_reason_desc, wp.wp_type
ORDER BY total_return_amt DESC
LIMIT 100
