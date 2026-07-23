SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    c.c_customer_id,
    ws.web_name,
    r.r_reason_desc,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount,
    CASE WHEN SUM(ss.ss_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS net_paid_category
FROM store_sales ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN store_returns sr
  ON ss.ss_item_sk = sr.sr_item_sk
  AND ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE d_sales.d_year = 2001
  AND ss.ss_list_price > 50.00
  AND r.r_reason_desc LIKE '%warranty%'
  AND ws.web_state = 'CA'
  AND ss.ss_quantity >= 2
GROUP BY
  d_sales.d_year,
  d_sales.d_month_seq,
  c.c_customer_id,
  ws.web_name,
  r.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
