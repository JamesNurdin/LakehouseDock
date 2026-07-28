SELECT
    s.s_state,
    ca.ca_city,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(wr.wr_return_ship_cost) AS total_return_ship_cost
FROM store_sales ss
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr
    ON ca.ca_address_sk = wr.wr_refunded_addr_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE ca.ca_state = 'CA'
  AND s.s_county = 'Mobile County'
  AND ss.ss_quantity > 1
  AND r_sr.r_reason_sk = 5
  AND sr.sr_return_amt > 100.00
  AND wr.wr_return_ship_cost BETWEEN 200 AND 500
GROUP BY GROUPING SETS ((s.s_state, ca.ca_city), (s.s_state), (ca.ca_city), ())
ORDER BY total_return_amount DESC, s.s_state
LIMIT 100
