WITH
  catalog_agg AS (
    SELECT
      'Catalog' AS source,
      d.d_year AS year,
      SUM(cs.cs_net_paid_inc_tax) AS net_paid,
      SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cs.cs_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 700
      )
    GROUP BY d.d_year
  ),
  web_agg AS (
    SELECT
      'Web' AS source,
      d.d_year AS year,
      SUM(ws.ws_net_paid_inc_tax) AS net_paid,
      SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND ws.ws_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 700
      )
    GROUP BY d.d_year
  ),
  union_all_agg AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
  ),
  rollup_agg AS (
    SELECT
      source,
      year,
      SUM(net_paid) AS total_net_paid,
      SUM(profit) AS total_profit,
      CASE
        WHEN SUM(profit) > 10000 THEN 'High'
        WHEN SUM(profit) > 0 THEN 'Medium'
        ELSE 'Low'
      END AS profit_bucket
    FROM union_all_agg
    GROUP BY ROLLUP (source, year)
  )
SELECT
  source,
  year,
  total_net_paid,
  total_profit,
  profit_bucket,
  ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_profit DESC) AS profit_rank,
  (SELECT AVG(profit) FROM union_all_agg) AS avg_profit_across_all
FROM rollup_agg
ORDER BY source, year NULLS LAST
LIMIT 100
