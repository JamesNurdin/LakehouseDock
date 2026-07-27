WITH filtered_returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_net_loss,
        sr.sr_reason_sk,
        sr.sr_addr_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_fee > 50
      AND sr.sr_return_ship_cost < 200
)
SELECT
    ca.ca_state,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_fee) AS avg_fee,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    MIN(sr.sr_net_loss) AS min_net_loss,
    MAX(sr.sr_net_loss) AS max_net_loss,
    SUM(ss.ss_sales_price * ss.ss_quantity) AS total_sales_value,
    AVG(ss.ss_coupon_amt) AS avg_coupon_amount
FROM filtered_returns sr
JOIN store_sales ss
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE ss.ss_sales_price BETWEEN 30 AND 100
  AND ca.ca_state = 'CA'
  AND r.r_reason_desc LIKE '%defect%'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE wr.wr_refunded_addr_sk = ca.ca_address_sk
          AND wr.wr_reason_sk = r.r_reason_sk
          AND wr.wr_return_quantity = 1
          AND wp.wp_type = 'article'
          AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
   )
GROUP BY ca.ca_state, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
