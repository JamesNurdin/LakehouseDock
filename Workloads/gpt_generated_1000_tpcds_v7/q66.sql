SELECT
    ca.ca_state,
    wp.wp_type,
    r.r_reason_desc,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(wr.wr_return_amt_inc_tax) AS avg_return_inc_tax,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_sold_date_sk) AS min_sold_date_sk,
    MAX(ws.ws_sold_date_sk) AS max_sold_date_sk
FROM tpcds.web_sales ws
JOIN tpcds.customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = ws.ws_item_sk
JOIN tpcds.reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE ca.ca_state = 'CA'
  AND wp.wp_type = 'content'
  AND r.r_reason_desc = 'Package was damaged'
  AND wr.wr_return_amt_inc_tax > 100.00
GROUP BY ca.ca_state, wp.wp_type, r.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
