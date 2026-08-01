WITH catalog_return_agg AS (
  SELECT
    cc.cc_name AS entity_name,
    sm.sm_type AS ship_mode_type,
    td.t_hour AS hour_of_day,
    SUM(cr.cr_return_amount) AS total_amount,
    COUNT(*) AS cnt,
    'CatalogReturn' AS source
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  WHERE cc.cc_rec_start_date >= DATE '2001-01-01'
    AND EXISTS (
      SELECT 1 FROM call_center cc2
      WHERE cc2.cc_market_manager = cc.cc_market_manager
        AND cc2.cc_state = 'CA'
    )
    AND cr.cr_return_amount > 0
  GROUP BY cc.cc_name, sm.sm_type, td.t_hour
),
web_sales_agg AS (
  SELECT
    p.p_promo_name AS entity_name,
    sm.sm_type AS ship_mode_type,
    td.t_hour AS hour_of_day,
    SUM(ws.ws_net_paid) AS total_amount,
    COUNT(*) AS cnt,
    'WebSales' AS source
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  WHERE p.p_discount_active = 'Y'
    AND ws.ws_net_paid > 0
  GROUP BY p.p_promo_name, sm.sm_type, td.t_hour
)
SELECT
  entity_name,
  ship_mode_type,
  hour_of_day,
  total_amount,
  cnt,
  source
FROM catalog_return_agg
UNION ALL
SELECT
  entity_name,
  ship_mode_type,
  hour_of_day,
  total_amount,
  cnt,
  source
FROM web_sales_agg
ORDER BY total_amount DESC, entity_name ASC
LIMIT 100
