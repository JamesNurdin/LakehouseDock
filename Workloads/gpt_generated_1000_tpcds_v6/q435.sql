WITH catalog_part AS (
  SELECT
    'catalog' AS source,
    ca.ca_state,
    ca.ca_location_type,
    hd.hd_vehicle_count,
    SUM(cr.cr_net_loss) AS total_net_loss
  FROM catalog_returns cr
  JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE cr.cr_net_loss > 1000
    AND hd.hd_vehicle_count >= 0
    AND ca.ca_location_type IN ('single family', 'condo')
  GROUP BY ca.ca_state, ca.ca_location_type, hd.hd_vehicle_count
),
store_part AS (
  SELECT
    'store' AS source,
    ca.ca_state,
    ca.ca_location_type,
    hd.hd_vehicle_count,
    SUM(sr.sr_net_loss) AS total_net_loss
  FROM store_returns sr
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE sr.sr_net_loss > 1000
    AND hd.hd_vehicle_count >= 0
    AND ca.ca_location_type IN ('single family', 'condo')
  GROUP BY ca.ca_state, ca.ca_location_type, hd.hd_vehicle_count
)
SELECT source,
       ca_state,
       ca_location_type,
       hd_vehicle_count,
       total_net_loss
FROM (
  SELECT source, ca_state, ca_location_type, hd_vehicle_count, total_net_loss FROM catalog_part
  UNION ALL
  SELECT source, ca_state, ca_location_type, hd_vehicle_count, total_net_loss FROM store_part
) combined
ORDER BY total_net_loss DESC
LIMIT 20
