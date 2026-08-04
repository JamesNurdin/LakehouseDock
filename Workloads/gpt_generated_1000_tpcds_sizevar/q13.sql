WITH catalog_sub AS (
  SELECT
    ca.ca_city,
    sm.sm_type,
    cr.cr_net_loss AS net_loss,
    1 AS cnt,
    'catalog' AS src
  FROM catalog_returns cr
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE ca.ca_country = 'United States'
    AND sm.sm_type = 'AIR'
    AND cr.cr_net_loss > 0
),
store_sub AS (
  SELECT
    ca.ca_city,
    CAST(NULL AS varchar) AS sm_type,
    sr.sr_net_loss AS net_loss,
    1 AS cnt,
    'store' AS src
  FROM store_returns sr
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE ca.ca_country = 'United States'
    AND sr.sr_net_loss > 0
)
SELECT
  city,
  src,
  sm_type,
  SUM(net_loss) AS total_net_loss,
  SUM(cnt) AS total_cnt
FROM (
  SELECT ca_city AS city, src, sm_type, net_loss, cnt FROM catalog_sub
  UNION ALL
  SELECT ca_city AS city, src, sm_type, net_loss, cnt FROM store_sub
) u
GROUP BY ROLLUP (city, src, sm_type)
ORDER BY city, src, sm_type
LIMIT 100
