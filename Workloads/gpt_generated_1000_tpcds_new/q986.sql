WITH
  full_inv_warehouse AS (
    SELECT
      w.w_warehouse_id,
      w.w_city,
      i.inv_item_sk,
      i.inv_quantity_on_hand,
      d.d_year
    FROM warehouse w
    FULL OUTER JOIN inventory i
      ON w.w_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN date_dim d
      ON i.inv_date_sk = d.d_date_sk
    WHERE w.w_country = 'United States' OR i.inv_quantity_on_hand > 100
  ),
  web_open_close AS (
    SELECT
      ws.web_site_id,
      ws.web_name,
      d_open.d_year AS open_year,
      d_close.d_year AS close_year,
      ws.web_gmt_offset
    FROM web_site ws
    JOIN date_dim d_open
      ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
      ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE ws.web_country = 'United States'
  ),
  intersect_keys AS (
    SELECT inv_item_sk FROM inventory
    INTERSECT
    SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 500
  )

SELECT
  entity_id,
  period_year,
  SUM(metric) AS total_metric,
  GROUPING(entity_id) AS grp_entity,
  GROUPING(period_year) AS grp_period
FROM (
  SELECT
    f.w_warehouse_id AS entity_id,
    f.d_year AS period_year,
    f.inv_quantity_on_hand AS metric
  FROM full_inv_warehouse f
  WHERE f.inv_item_sk IN (SELECT inv_item_sk FROM intersect_keys)
) AS src1
GROUP BY ROLLUP (entity_id, period_year)

UNION

SELECT
  entity_id,
  period_year,
  SUM(metric) AS total_metric,
  GROUPING(entity_id) AS grp_entity,
  GROUPING(period_year) AS grp_period
FROM (
  SELECT
    ws.web_site_id AS entity_id,
    ws.open_year AS period_year,
    0 AS metric
  FROM web_open_close ws
) AS src2
GROUP BY ROLLUP (entity_id, period_year)

ORDER BY total_metric DESC
OFFSET 0
LIMIT 100
