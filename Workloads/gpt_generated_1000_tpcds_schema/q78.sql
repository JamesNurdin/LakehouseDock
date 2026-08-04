WITH
  cat_filtered AS (
    SELECT
      cs.cs_ship_mode_sk,
      cs.cs_net_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ext_wholesale_cost < 3000
      AND sm.sm_carrier = 'AIRBORNE'
      AND cs.cs_ship_mode_sk IN (
        SELECT sm2.sm_ship_mode_sk
        FROM tpcds.ship_mode sm2
        WHERE sm2.sm_code = 'AIR'
      )
  ),
  cat_agg AS (
    SELECT
      sm.sm_carrier,
      SUM(cs.cs_net_profit) AS total_cat_profit
    FROM cat_filtered cs
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_carrier
  ),
  web_filtered AS (
    SELECT
      ws.ws_ship_mode_sk,
      ws.ws_net_profit,
      ws.ws_ext_wholesale_cost,
      wp.wp_link_count,
      ws.ws_web_page_sk,
      ws.ws_web_site_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ws.ws_ext_wholesale_cost > 1000
      AND wp.wp_link_count > 10
      AND wsit.web_street_name LIKE '%Broadway%'
      AND sm.sm_carrier = 'AIRBORNE'
  ),
  web_agg AS (
    SELECT
      sm.sm_carrier,
      SUM(ws.ws_net_profit) AS total_web_profit,
      COUNT(*) AS web_txn_count
    FROM web_filtered ws
    JOIN tpcds.ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_carrier
  ),
  combined AS (
    SELECT
      ca.sm_carrier AS carrier,
      ca.total_cat_profit,
      wa.total_web_profit,
      wa.web_txn_count,
      (ca.total_cat_profit + wa.total_web_profit) AS total_profit
    FROM cat_agg ca
    JOIN web_agg wa
      ON ca.sm_carrier = wa.sm_carrier
    WHERE ca.total_cat_profit > 0
      AND wa.total_web_profit > 0
  )
SELECT
  carrier,
  total_cat_profit,
  total_web_profit,
  web_txn_count,
  total_profit,
  ROUND(total_profit / web_txn_count, 2) AS avg_profit_per_txn
FROM combined
ORDER BY total_profit DESC
LIMIT 100
