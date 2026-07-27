SELECT
  c.c_customer_id,
  ca.ca_zip,
  CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
  ss.ss_net_profit,
  RANK() OVER (PARTITION BY ca.ca_zip ORDER BY ss.ss_net_profit DESC) AS profit_rank,
  SUM(ss.ss_net_profit) OVER (PARTITION BY ca.ca_zip) AS total_profit_zip
FROM store_sales ss
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_item_sk = sr.sr_item_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
  AND cr.cr_refunded_addr_sk = ca.ca_address_sk
  AND cr.cr_reason_sk = r.r_reason_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
  AND ca.ca_zip LIKE '9%'
  AND ca.ca_location_type = 'apartment'
  AND c.c_preferred_cust_flag = 'Y'
  AND r.r_reason_desc IN ('Damaged', 'Defective')
  AND cr.cr_net_loss > 0
  AND sr.sr_store_credit > 100
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_discount_active = 'Y'
      )
ORDER BY profit_rank ASC, total_profit_zip DESC
LIMIT 100
