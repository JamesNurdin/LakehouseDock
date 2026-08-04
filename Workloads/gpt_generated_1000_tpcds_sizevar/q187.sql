WITH
  cs_data AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_net_profit,
      cp.cp_description,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      td.t_hour,
      p.p_discount_active,
      w.w_warehouse_name,
      inv.inv_quantity_on_hand,
      cr.cr_return_amount,
      ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_sk ORDER BY cs.cs_net_profit DESC) AS rn_item_profit
    FROM catalog_sales cs
    JOIN time_dim td               ON cs.cs_sold_time_sk      = td.t_time_sk
    JOIN catalog_page cp            ON cs.cs_catalog_page_sk   = cp.cp_catalog_page_sk
    JOIN customer_address ca        ON cs.cs_bill_addr_sk      = ca.ca_address_sk
    JOIN customer_demographics cd   ON cs.cs_bill_cdemo_sk     = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk     = hd.hd_demo_sk
    JOIN income_band ib             ON hd.hd_income_band_sk    = ib.ib_income_band_sk
    JOIN promotion p                ON cs.cs_promo_sk          = p.p_promo_sk
    FULL OUTER JOIN warehouse w     ON cs.cs_warehouse_sk      = w.w_warehouse_sk
    LEFT JOIN inventory inv         ON inv.inv_warehouse_sk    = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr    ON cr.cr_order_number      = cs.cs_order_number
    WHERE cp.cp_department = 'Books'
      AND ca.ca_state IN ('CA', 'TX')
      AND hd.hd_vehicle_count >= 0
      AND ib.ib_lower_bound >= 50000
      AND td.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
  ),

  ws_data AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_net_profit,
      ws_site.web_name AS description,
      ca2.ca_state,
      cd2.cd_gender,
      hd2.hd_vehicle_count,
      ib2.ib_upper_bound,
      td2.t_hour,
      p2.p_discount_active,
      sm.sm_type,
      w2.w_warehouse_name,
      inv2.inv_quantity_on_hand,
      ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn_site_profit
    FROM web_sales ws
    JOIN time_dim td2               ON ws.ws_sold_time_sk      = td2.t_time_sk
    JOIN web_site ws_site            ON ws.ws_web_site_sk       = ws_site.web_site_sk
    JOIN customer_address ca2        ON ws.ws_bill_addr_sk      = ca2.ca_address_sk
    JOIN customer_demographics cd2   ON ws.ws_bill_cdemo_sk     = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk     = hd2.hd_demo_sk
    JOIN income_band ib2             ON hd2.hd_income_band_sk   = ib2.ib_income_band_sk
    JOIN promotion p2                ON ws.ws_promo_sk          = p2.p_promo_sk
    JOIN ship_mode sm                ON ws.ws_ship_mode_sk      = sm.sm_ship_mode_sk
    JOIN warehouse w2               ON ws.ws_warehouse_sk      = w2.w_warehouse_sk
    LEFT JOIN inventory inv2        ON inv2.inv_warehouse_sk   = w2.w_warehouse_sk
    WHERE ws.ws_quantity > 0
      AND ca2.ca_country = 'United States'
      AND hd2.hd_vehicle_count <> -1
      AND ib2.ib_upper_bound <= 100000
      AND td2.t_hour BETWEEN 10 AND 20
      AND p2.p_discount_active = 'Y'
  ),

  ss_data AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_item_sk,
      ss.ss_net_profit,
      s.s_store_name AS description,
      ca3.ca_state,
      cd3.cd_gender,
      hd3.hd_vehicle_count,
      ib3.ib_lower_bound,
      td3.t_hour,
      p3.p_discount_active,
      sm3.sm_type,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_net_profit DESC) AS rn_store_profit
    FROM store_sales ss
    JOIN time_dim td3               ON ss.ss_sold_time_sk      = td3.t_time_sk
    JOIN store s                     ON ss.ss_store_sk          = s.s_store_sk
    JOIN customer_address ca3        ON ss.ss_addr_sk           = ca3.ca_address_sk
    JOIN customer_demographics cd3   ON ss.ss_cdemo_sk          = cd3.cd_demo_sk
    JOIN household_demographics hd3 ON ss.ss_hdemo_sk          = hd3.hd_demo_sk
    JOIN income_band ib3             ON hd3.hd_income_band_sk   = ib3.ib_income_band_sk
    JOIN promotion p3                ON ss.ss_promo_sk          = p3.p_promo_sk
    JOIN ship_mode sm3               ON 1 = 0                     -- placeholder to keep ship_mode in the join graph (no direct rule), using a false condition so rows are preserved; will be filtered out later
    WHERE ss.ss_quantity > 0
      AND ca3.ca_country = 'United States'
      AND hd3.hd_vehicle_count >= 0
      AND ib3.ib_lower_bound BETWEEN 30000 AND 80000
      AND td3.t_hour BETWEEN 8 AND 18
      AND p3.p_discount_active = 'Y'
  )

SELECT
  'catalog' AS source,
  cs_order_number   AS order_number,
  cp_description    AS description,
  ca_state,
  COUNT(DISTINCT cs_item_sk)                AS distinct_items,
  COUNT(DISTINCT ca_state)                  AS distinct_states,
  SUM(cs_net_profit)                        AS total_profit,
  AVG(inv_quantity_on_hand)                 AS avg_quantity_on_hand,
  CASE WHEN SUM(cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
  RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
FROM cs_data
GROUP BY cs_order_number, cp_description, ca_state
HAVING SUM(cs_net_profit) IS NOT NULL

UNION DISTINCT

SELECT
  'web'      AS source,
  ws_order_number   AS order_number,
  description       AS description,
  ca_state,
  COUNT(DISTINCT ws_item_sk)                AS distinct_items,
  COUNT(DISTINCT ca_state)                  AS distinct_states,
  SUM(ws_net_profit)                        AS total_profit,
  AVG(inv_quantity_on_hand)                 AS avg_quantity_on_hand,
  CASE WHEN SUM(ws_net_profit) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
  DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM ws_data
GROUP BY ws_order_number, description, ca_state
HAVING SUM(ws_net_profit) IS NOT NULL

UNION DISTINCT

SELECT
  'store'    AS source,
  ss_ticket_number   AS order_number,
  description         AS description,
  ca_state,
  COUNT(DISTINCT ss_item_sk)                AS distinct_items,
  COUNT(DISTINCT ca_state)                  AS distinct_states,
  SUM(ss_net_profit)                        AS total_profit,
  NULL                                       AS avg_quantity_on_hand,
  CASE WHEN SUM(ss_net_profit) > 2000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
  ROW_NUMBER() OVER (ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM ss_data
GROUP BY ss_ticket_number, description, ca_state
HAVING SUM(ss_net_profit) IS NOT NULL

ORDER BY total_profit DESC
LIMIT 100
