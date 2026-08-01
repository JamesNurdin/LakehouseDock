WITH
  store_part AS (
    SELECT
      p.p_promo_id AS promo_id,
      ss.ss_net_profit AS net_profit,
      ss.ss_quantity AS quantity,
      'store' AS source,
      s.s_state AS state
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ss.ss_net_profit IS NOT NULL
      AND ss.ss_quantity > 0
      AND s.s_floor_space > 5000000
      AND s.s_rec_start_date >= DATE '1999-01-01'
  ),
  catalog_part AS (
    SELECT
      p.p_promo_id AS promo_id,
      cs.cs_net_profit AS net_profit,
      cs.cs_quantity AS quantity,
      'catalog' AS source,
      cp.cp_department AS state
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    WHERE cp.cp_department = 'Electronics'
      AND w.w_state = 'TX'
      AND cc.cc_gmt_offset > -5
      AND cs.cs_quantity > 1
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND p.p_discount_active = 'Y'
  ),
  web_part AS (
    SELECT
      p.p_promo_id AS promo_id,
      ws.ws_net_profit AS net_profit,
      ws.ws_quantity AS quantity,
      'web' AS source,
      wsite.web_state AS state
    FROM web_sales ws
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE wsite.web_state = 'NY'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND ws.ws_quantity > 2
      AND ws.ws_net_paid > 1000
      AND w.w_state = 'NY'
  ),
  union_all AS (
    SELECT * FROM store_part
    UNION DISTINCT
    SELECT * FROM catalog_part
    UNION DISTINCT
    SELECT * FROM web_part
  ),
  intersect_promo AS (
    SELECT promo_id FROM store_part
    INTERSECT
    SELECT promo_id FROM catalog_part
  ),
  full_joined AS (
    SELECT
      sp.promo_id,
      sp.net_profit AS store_profit,
      cp.net_profit AS catalog_profit
    FROM store_part sp
    FULL OUTER JOIN catalog_part cp ON sp.promo_id = cp.promo_id
  )
SELECT
  u.promo_id,
  u.source,
  u.state,
  u.net_profit,
  u.quantity,
  lp.total_profit,
  fj.store_profit,
  fj.catalog_profit,
  ip.promo_id AS intersected_promo
FROM union_all u
LEFT JOIN LATERAL (
  SELECT sum(u2.net_profit) AS total_profit
  FROM union_all u2
  WHERE u2.promo_id = u.promo_id
) lp ON TRUE
LEFT JOIN full_joined fj ON u.promo_id = fj.promo_id
LEFT JOIN intersect_promo ip ON u.promo_id = ip.promo_id
WHERE u.net_profit > 0
  AND u.quantity > 0
  AND u.state IS NOT NULL
  AND u.source IN ('store', 'catalog', 'web')
  AND u.promo_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM catalog_part cp WHERE cp.promo_id = u.promo_id AND cp.quantity > 5
  )
ORDER BY u.net_profit DESC
LIMIT 100
