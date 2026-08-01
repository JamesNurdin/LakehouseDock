WITH ws_agg AS (
  SELECT
    ws.ws_ship_mode_sk,
    SUM(ws.ws_net_paid_inc_ship_tax) AS ws_total_net_paid,
    SUM(ws.ws_quantity) AS ws_total_quantity
  FROM web_sales ws
  WHERE ws.ws_quantity > 0
  GROUP BY ws.ws_ship_mode_sk
),
joined_facts AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_paid_inc_ship_tax,
    sm.sm_ship_mode_sk,
    sm.sm_ship_mode_id,
    sm.sm_type,
    sm.sm_code,
    sm.sm_carrier,
    cr.cr_return_amount,
    cr.cr_net_loss,
    ws_agg.ws_total_net_paid,
    ws_agg.ws_total_quantity,
    ARRAY[sm.sm_code, sm.sm_carrier] AS ship_info
  FROM catalog_sales cs
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN ws_agg
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2451500 AND 2452000
    AND cs.cs_quantity > 1
    AND sm.sm_code IN ('AIR', 'SURFACE')
    AND cs.cs_net_paid_inc_ship_tax > 500
    AND (cr.cr_return_amount IS NOT NULL OR ws_agg.ws_total_net_paid IS NOT NULL)
),
aggregated AS (
  SELECT
    cs_order_number,
    sm_ship_mode_id,
    sm_type,
    SUM(cs_net_paid_inc_ship_tax) AS total_sales,
    SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
    SUM(COALESCE(cr_net_loss, 0)) AS total_loss,
    SUM(COALESCE(ws_total_net_paid, 0)) AS ws_total_sales,
    SUM(COALESCE(ws_total_quantity, 0)) AS ws_total_quantity,
    ship_info
  FROM joined_facts
  GROUP BY cs_order_number, sm_ship_mode_id, sm_type, ship_info
)
SELECT
  cs_order_number,
  sm_ship_mode_id,
  sm_type,
  CASE
    WHEN total_returns = 0 THEN 'NO_RETURN'
    WHEN total_returns < 100 THEN 'SMALL_RETURN'
    ELSE 'LARGE_RETURN'
  END AS return_category,
  total_sales,
  total_returns,
  total_loss,
  ws_total_sales,
  ws_total_quantity,
  RANK() OVER (PARTITION BY sm_type ORDER BY total_sales DESC) AS sales_rank,
  ROW_NUMBER() OVER (ORDER BY total_loss DESC) AS loss_rank,
  ship_detail
FROM aggregated
CROSS JOIN UNNEST(ship_info) AS t(ship_detail)
ORDER BY total_sales DESC
LIMIT 100
