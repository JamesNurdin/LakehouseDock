WITH joined_data AS (
  SELECT
    cp.cp_catalog_page_number,
    cp.cp_type,
    ca.ca_state,
    ca.ca_suite_number,
    hd.hd_vehicle_count,
    cr.cr_fee,
    cr.cr_return_amt_inc_tax,
    sr.sr_return_amt,
    cr.cr_return_quantity,
    cr.cr_order_number,
    sr.sr_ticket_number
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
  WHERE cp.cp_catalog_page_number IN (15, 13, 5)
    AND cp.cp_end_date_sk BETWEEN 2450905 AND 2451270
    AND hd.hd_vehicle_count > 2
    AND ca.ca_suite_number IN ('Suite O', 'Suite Q', 'Suite Y')
    AND ca.ca_state = 'CA'
    AND cr.cr_fee > 10
    AND cr.cr_return_amt_inc_tax > 500
    AND sr.sr_return_amt > 100
    AND cr.cr_return_quantity > 1
)
SELECT
  cp_catalog_page_number,
  cp_type,
  ca_state,
  ca_suite_number,
  hd_vehicle_count,
  cr_fee,
  cr_return_amt_inc_tax,
  sr_return_amt,
  CASE WHEN cr_return_amt_inc_tax > 1000 THEN 'High' ELSE 'Normal' END AS return_category,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY cr_return_amt_inc_tax DESC) AS rn_state_by_cr_return,
  RANK() OVER (ORDER BY (cr_return_amt_inc_tax + sr_return_amt) DESC) AS overall_return_rank,
  SUM(cr_return_amt_inc_tax) OVER (PARTITION BY cp_catalog_page_number) AS sum_return_by_page,
  AVG(sr_return_amt) OVER (PARTITION BY ca_state) AS avg_sr_return_by_state
FROM joined_data
ORDER BY overall_return_rank
LIMIT 100
