WITH filtered_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    i.i_product_name,
    i.i_item_desc,
    i.i_brand,
    ws.ws_net_paid,
    ws.ws_net_paid_inc_tax,
    ws.ws_sold_time_sk,
    t.t_shift,
    t.t_am_pm,
    sm.sm_ship_mode_id,
    sm.sm_contract,
    sm.sm_code,
    ws.ws_promo_sk,
    -- previous net paid for the same item (ordered by time surrogate key)
    LAG(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_time_sk) AS prev_net_paid,
    -- profit tier based on net paid
    CASE
      WHEN ws.ws_net_paid > 1000 THEN 'high'
      WHEN ws.ws_net_paid BETWEEN 500 AND 1000 THEN 'medium'
      ELSE 'low'
    END AS profit_category,
    -- average net paid for the brand (scalar correlated subquery)
    (SELECT AVG(ws2.ws_net_paid)
     FROM web_sales ws2
     JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
     WHERE i2.i_brand = i.i_brand) AS brand_avg_net_paid,
    -- extract the numeric part of the contract string
    regexp_extract(sm.sm_contract, '(\\d+)', 1) AS contract_number
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE regexp_like(i.i_item_desc, '(?i)premium')
    AND sm.sm_contract LIKE '%mM8l%'
    AND sm.sm_code = 'AIR'
    AND NOT EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_promo_sk = ws.ws_promo_sk
        AND p.p_discount_active = 'Y'
    )
)
SELECT
  fs.ws_order_number,
  fs.i_product_name,
  fs.i_brand,
  fs.t_shift,
  fs.t_am_pm,
  fs.sm_ship_mode_id,
  fs.contract_number,
  fs.profit_category,
  fs.ws_net_paid,
  fs.prev_net_paid,
  fs.brand_avg_net_paid,
  CASE
    WHEN fs.ws_net_paid > fs.brand_avg_net_paid THEN 1
    ELSE 0
  END AS above_brand_avg
FROM filtered_sales fs
ORDER BY fs.ws_net_paid DESC
LIMIT 100
