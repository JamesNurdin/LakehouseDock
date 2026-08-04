WITH aggregated AS (
  SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    td.t_shift,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ws.ws_net_paid) AS web_net_paid,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_store_items,
    SUM(DISTINCT cr.cr_return_amount) AS distinct_return_amount_sum
  FROM catalog_returns cr
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
  LEFT JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cr.cr_return_amount > 20.00
    AND sm.sm_type = 'REGULAR'
    AND td.t_hour BETWEEN 8 AND 20
    AND ws.ws_ext_tax < 500.00
    AND ss.ss_quantity >= 10
  GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_type,
    td.t_shift
)
SELECT
  sm_ship_mode_id,
  sm_type,
  t_shift,
  store_net_paid,
  web_net_paid,
  (store_net_paid + web_net_paid) AS total_net_paid,
  distinct_store_items,
  distinct_return_amount_sum,
  ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY (store_net_paid + web_net_paid) DESC) AS rn
FROM aggregated
ORDER BY rn
LIMIT 100
