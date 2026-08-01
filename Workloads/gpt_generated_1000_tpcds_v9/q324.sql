SELECT
  ss.ss_ticket_number,
  ss.ss_sold_date_sk,
  time_dim.t_hour,
  customer.c_customer_id,
  customer_address.ca_city,
  household_demographics.hd_income_band_sk,
  ss.ss_quantity,
  ss.ss_net_profit,
  RANK() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY ss.ss_net_profit DESC) AS profit_rank,
  (
    SELECT COUNT(*)
    FROM store_returns sr2
    WHERE sr2.sr_ticket_number = ss.ss_ticket_number
  ) AS return_count,
  (
    SELECT w.w_warehouse_name
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_refunded_customer_sk = customer.c_customer_sk
    ORDER BY cr.cr_returned_date_sk
    LIMIT 1
  ) AS warehouse_name,
  (
    SELECT r.r_reason_desc
    FROM reason r
    WHERE r.r_reason_sk = sr.sr_reason_sk
  ) AS return_reason_desc
FROM store_sales ss
JOIN time_dim ON ss.ss_sold_time_sk = time_dim.t_time_sk
JOIN customer ON ss.ss_customer_sk = customer.c_customer_sk
JOIN household_demographics ON ss.ss_hdemo_sk = household_demographics.hd_demo_sk
JOIN customer_address ON ss.ss_addr_sk = customer_address.ca_address_sk
JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
  AND sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_customer_sk = customer.c_customer_sk
  AND sr.sr_hdemo_sk = household_demographics.hd_demo_sk
  AND sr.sr_addr_sk = customer_address.ca_address_sk
WHERE time_dim.t_hour BETWEEN 8 AND 12
  AND household_demographics.hd_income_band_sk = 5
  AND sr.sr_return_quantity > 0
  AND customer_address.ca_state = 'CA'
  AND EXISTS (
    SELECT 1
    FROM reason r
    WHERE r.r_reason_sk = sr.sr_reason_sk
      AND r.r_reason_desc LIKE '%Not Satisfied%'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_refunded_customer_sk = customer.c_customer_sk
      AND w.w_state = 'CA'
  )
ORDER BY ss.ss_net_profit DESC
LIMIT 100
