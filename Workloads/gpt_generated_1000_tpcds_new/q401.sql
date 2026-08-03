WITH
  item_stats AS (
    SELECT i_brand,
           i_category,
           AVG(i_wholesale_cost) AS avg_wholesale_cost,
           COUNT(*) AS cnt
    FROM item
    GROUP BY i_brand, i_category
  ),
  promo_distinct AS (
    SELECT DISTINCT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
  ),
  catalog_agg AS (
    SELECT cs.cs_call_center_sk,
           cs.cs_catalog_page_sk,
           cs.cs_ship_mode_sk,
           cs.cs_warehouse_sk,
           cs.cs_item_sk,
           cs.cs_promo_sk,
           SUM(cs.cs_net_profit) AS profit_cs,
           SUM(cs.cs_quantity)   AS qty_cs
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk,
             cs.cs_catalog_page_sk,
             cs.cs_ship_mode_sk,
             cs.cs_warehouse_sk,
             cs.cs_item_sk,
             cs.cs_promo_sk
  ),
  web_agg AS (
    SELECT ws.ws_ship_mode_sk,
           ws.ws_warehouse_sk,
           ws.ws_item_sk,
           ws.ws_promo_sk,
           SUM(ws.ws_net_profit) AS profit_ws,
           SUM(ws.ws_quantity)   AS qty_ws
    FROM web_sales ws
    GROUP BY ws.ws_ship_mode_sk,
             ws.ws_warehouse_sk,
             ws.ws_item_sk,
             ws.ws_promo_sk
  )

SELECT
  i1.i_brand                                   AS brand,
  i1.i_category                               AS category,
  cc.cc_state                                 AS state,
  CASE WHEN SUM(ca.profit_cs) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
  SUM(ca.profit_cs)                           AS total_profit,
  SUM(ca.qty_cs)                              AS total_qty,
  (SELECT COUNT(*) FROM item_stats)          AS brand_category_combos
FROM catalog_agg ca
JOIN call_center cc      ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp      ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm1        ON ca.cs_ship_mode_sk   = sm1.sm_ship_mode_sk
JOIN ship_mode sm2        ON ca.cs_ship_mode_sk   = sm2.sm_ship_mode_sk   -- second alias
JOIN warehouse wh1        ON ca.cs_warehouse_sk   = wh1.w_warehouse_sk
JOIN warehouse wh2        ON ca.cs_warehouse_sk   = wh2.w_warehouse_sk   -- second alias
JOIN item i1              ON ca.cs_item_sk        = i1.i_item_sk
JOIN promotion p1         ON ca.cs_promo_sk       = p1.p_promo_sk
JOIN promo_distinct pd    ON ca.cs_promo_sk       = pd.p_promo_sk
GROUP BY CUBE (i1.i_brand, i1.i_category, cc.cc_state)

UNION

SELECT
  i2.i_brand                                   AS brand,
  i2.i_category                               AS category,
  cc2.cc_state                                AS state,
  CASE WHEN SUM(wa.profit_ws) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
  SUM(wa.profit_ws)                           AS total_profit,
  SUM(wa.qty_ws)                              AS total_qty,
  (SELECT COUNT(*) FROM item_stats)          AS brand_category_combos
FROM web_agg wa
JOIN item i2               ON wa.ws_item_sk   = i2.i_item_sk
JOIN promotion p2          ON wa.ws_promo_sk  = p2.p_promo_sk
JOIN ship_mode sm3         ON wa.ws_ship_mode_sk = sm3.sm_ship_mode_sk
JOIN ship_mode sm4         ON wa.ws_ship_mode_sk = sm4.sm_ship_mode_sk   -- second alias
JOIN warehouse wh3         ON wa.ws_warehouse_sk = wh3.w_warehouse_sk
JOIN warehouse wh4         ON wa.ws_warehouse_sk = wh4.w_warehouse_sk   -- second alias
JOIN promo_distinct pd2    ON wa.ws_promo_sk  = pd2.p_promo_sk
-- dummy join to bring call_center into the query tree
JOIN call_center cc2       ON cc2.cc_country = cc2.cc_country
GROUP BY CUBE (i2.i_brand, i2.i_category, cc2.cc_state)

EXCEPT

SELECT
  i.i_brand        AS brand,
  i.i_category    AS category,
  cc.cc_state     AS state,
  'Low'           AS profit_category,
  CAST(0 AS decimal(7,2)) AS total_profit,
  CAST(0 AS integer)      AS total_qty,
  (SELECT COUNT(*) FROM item_stats) AS brand_category_combos
FROM item i
JOIN call_center cc ON cc.cc_country = cc.cc_country
WHERE i.i_wholesale_cost < 0.5

ORDER BY total_profit DESC, brand
LIMIT 100
