WITH
  agg_catalog AS (
    SELECT
      cs_ship_mode_sk,
      sum(cs_ext_sales_price)      AS total_sales,
      sum(cs_net_profit)           AS total_profit,
      count(*)                     AS order_cnt
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_ext_ship_cost   > 500
      AND cs_net_paid_inc_tax BETWEEN 1000 AND 3000
      AND cs_ext_wholesale_cost > 1000
      AND cs_quantity > 1
    GROUP BY cs_ship_mode_sk
  ),
  agg_web AS (
    SELECT
      ws_ship_mode_sk,
      sum(ws_ext_sales_price)      AS web_total_sales,
      sum(ws_net_profit)           AS web_total_profit,
      count(*)                     AS web_order_cnt
    FROM web_sales
    WHERE ws_ext_ship_cost   > 500
      AND ws_net_paid_inc_tax > 1000
      AND ws_quantity        > 2
      AND ws_ext_sales_price > 100
    GROUP BY ws_ship_mode_sk
  ),
  common_modes AS (
    SELECT cs_ship_mode_sk AS sm_ship_mode_sk FROM agg_catalog WHERE total_sales > 5000
    INTERSECT
    SELECT ws_ship_mode_sk FROM agg_web WHERE web_total_sales > 5000
  ),
  ws_site AS (
    SELECT
      ws_ship_mode_sk,
      ws_web_site_sk,
      sum(ws_ext_sales_price) AS site_sales
    FROM web_sales
    TABLESAMPLE BERNOULLI (5)
    WHERE ws_ext_ship_cost > 100
      AND ws_quantity > 1
    GROUP BY ws_ship_mode_sk, ws_web_site_sk
  ),
  site_details AS (
    SELECT
      ws.ws_ship_mode_sk,
      ws.ws_web_site_sk,
      ws.site_sales,
      w.web_site_id,
      w.web_manager,
      ARRAY[ws.site_sales, ws.site_sales * 0.2] AS metrics
    FROM ws_site ws
    JOIN web_site w ON w.web_site_sk = ws.ws_web_site_sk
  )
SELECT
  sm.sm_ship_mode_id,
  sm.sm_type,
  agg_c.total_sales,
  agg_c.total_profit,
  agg_c.order_cnt,
  agg_w.web_total_sales,
  agg_w.web_total_profit,
  agg_w.web_order_cnt,
  sd.site_sales,
  sd.web_site_id,
  sd.web_manager,
  RANK() OVER (ORDER BY agg_c.total_sales DESC)          AS sales_rank,
  CASE WHEN agg_c.total_profit > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_flag,
  t.metric_val                                           AS metric_value
FROM common_modes cm
JOIN ship_mode sm ON sm.sm_ship_mode_sk = cm.sm_ship_mode_sk
LEFT JOIN agg_catalog agg_c ON agg_c.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN agg_web agg_w ON agg_w.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN site_details sd ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN UNNEST(sd.metrics) AS t(metric_val)
WHERE sm.sm_contract LIKE 'Y%'
  AND sm.sm_code = 'AIR'
  AND sd.web_manager = 'Julio Davis'
ORDER BY agg_c.total_sales DESC, sm.sm_ship_mode_id
LIMIT 100
