WITH agg AS (
  SELECT
    cp.cp_type AS cp_type,
    hd.hd_buy_potential AS hd_buy_potential,
    ca.ca_state AS ca_state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
  WHERE cp.cp_end_date_sk BETWEEN 2450844 AND 2451088
    AND cr.cr_return_amount > 0
    AND cp.cp_catalog_page_number >= 2
  GROUP BY cp.cp_type, hd.hd_buy_potential, ca.ca_state
)
SELECT
  cp_type,
  hd_buy_potential,
  ca_state,
  total_return_amount,
  avg_net_loss,
  total_return_qty,
  distinct_orders,
  RANK() OVER (PARTITION BY cp_type ORDER BY total_return_amount DESC) AS rank_in_type
FROM agg
WHERE total_return_amount > 1000
ORDER BY cp_type, rank_in_type
LIMIT 100
