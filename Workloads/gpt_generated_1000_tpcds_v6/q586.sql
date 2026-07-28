WITH
  cs_sales AS (
    SELECT
      t.t_time_id        AS time_id,
      sm.sm_type         AS ship_type,
      CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_category,
      SUM(cs.cs_net_paid_inc_tax) AS total_net_paid
    FROM
      catalog_sales cs
      JOIN time_dim t   ON cs.cs_sold_time_sk = t.t_time_sk
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
      cs.cs_net_paid_inc_tax > 1000
    GROUP BY
      t.t_time_id,
      sm.sm_type,
      CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END
    HAVING
      SUM(cs.cs_net_paid_inc_tax) > 2000
  ),
  ws_sales AS (
    SELECT
      t.t_time_id        AS time_id,
      sm.sm_type         AS ship_type,
      CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_category,
      SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM
      web_sales ws
      JOIN time_dim t   ON ws.ws_sold_time_sk = t.t_time_sk
      JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
      ws.ws_net_paid_inc_tax > 1000
    GROUP BY
      t.t_time_id,
      sm.sm_type,
      CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END
    HAVING
      SUM(ws.ws_net_paid_inc_tax) > 2000
  )
SELECT
  time_id,
  ship_type,
  ship_category,
  total_net_paid
FROM cs_sales
UNION ALL
SELECT
  time_id,
  ship_type,
  ship_category,
  total_net_paid
FROM ws_sales
ORDER BY time_id, ship_type
