SELECT
    s.s_store_name,
    ca.ca_state,
    r.r_reason_desc,
    wp.wp_type,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(sr.sr_net_loss) AS total_loss,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    AVG(wr.wr_return_amt) AS avg_web_return_amt,
    MIN(ss.ss_sales_price) AS min_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr
  ON r.r_reason_sk = wr.wr_reason_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE ss.ss_sales_price > 100
  AND ca.ca_state = 'CA'
  AND s.s_country = 'United States'
  AND r.r_reason_id IN ('AAAAAAAADBAAAAAA','AAAAAAAAGAAAAAAA')
  AND wp.wp_link_count >= 10
  AND wr.wr_return_ship_cost < 500
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ss.ss_ticket_number
      )
GROUP BY
    s.s_store_name,
    ca.ca_state,
    r.r_reason_desc,
    wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
