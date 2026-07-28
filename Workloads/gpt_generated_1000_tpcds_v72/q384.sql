WITH sales_demo AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_hdemo_sk,
    ss.ss_addr_sk,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    ca.ca_state,
    ca.ca_city,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM store_sales ss
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
    AND ss.ss_net_paid > 100
    AND hd.hd_vehicle_count >= 2
    AND ca.ca_state IN ('CA','TX','NY')
    AND ib.ib_lower_bound >= 50000
    AND ib.ib_upper_bound <= 150000
)
SELECT
  sd.ca_state,
  sd.ca_city,
  cc.cc_manager,
  cp.cp_type,
  r.r_reason_desc,
  SUM(sd.ss_net_profit) AS total_profit,
  AVG(sd.ss_net_profit) AS avg_profit,
  RANK() OVER (PARTITION BY sd.ca_state ORDER BY SUM(sd.ss_net_profit) DESC) AS state_profit_rank,
  CASE
    WHEN SUM(sd.ss_net_profit) > (SELECT AVG(ss_net_profit) FROM store_sales) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS profit_category
FROM sales_demo sd
JOIN catalog_returns cr
  ON cr.cr_refunded_hdemo_sk = sd.ss_hdemo_sk
  AND cr.cr_refunded_addr_sk = sd.ss_addr_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE cc.cc_manager = 'Richard James'
  AND cc.cc_mkt_class LIKE '%Exp%'
  AND cp.cp_type = 'C'
  AND r.r_reason_desc LIKE '%customer%'
  AND cr.cr_return_quantity > 0
  AND cr.cr_return_amount > 0
GROUP BY
  sd.ca_state,
  sd.ca_city,
  cc.cc_manager,
  cp.cp_type,
  r.r_reason_desc
HAVING SUM(sd.ss_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
