WITH logs AS (
  SELECT
    TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS wl_item_id,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_ts
  FROM iceberg.bigbenchv2_sf1.web_logs
  WHERE TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) = 7
),

tmp1 AS (
  SELECT
    i.i_item_id,
    (i.i_comp_price - i.i_price) / i.i_price AS price_change,
    l.wl_ts AS start_date
  FROM iceberg.bigbenchv2_sf1.items i
  JOIN logs l
    ON i.i_item_id = l.wl_item_id
  WHERE i.i_comp_price < i.i_price
),

tmp2 AS (
  SELECT
    ws.ws_item_id,
    SUM(
      CASE
        WHEN TRY_CAST(ws.ws_ts AS timestamp) >= c.start_date
        THEN ws.ws_quantity
        ELSE 0
      END
    ) AS current_ws,
    SUM(
      CASE
        WHEN TRY_CAST(ws.ws_ts AS timestamp) < c.start_date
        THEN ws.ws_quantity
        ELSE 0
      END
    ) AS prev_ws
  FROM iceberg.bigbenchv2_sf1.web_sales ws
  JOIN tmp1 c
    ON ws.ws_item_id = c.i_item_id
  GROUP BY ws.ws_item_id
),

tmp3 AS (
  SELECT
    ss.ss_item_id,
    SUM(
      CASE
        WHEN TRY_CAST(ss.ss_ts AS timestamp) >= c.start_date
        THEN ss.ss_quantity
        ELSE 0
      END
    ) AS current_ss,
    SUM(
      CASE
        WHEN TRY_CAST(ss.ss_ts AS timestamp) < c.start_date
        THEN ss.ss_quantity
        ELSE 0
      END
    ) AS prev_ss
  FROM iceberg.bigbenchv2_sf1.store_sales ss
  JOIN tmp1 c
    ON ss.ss_item_id = c.i_item_id
  GROUP BY ss.ss_item_id
)

SELECT DISTINCT
  c.i_item_id,
  CAST(
    (tmp3.current_ss + tmp2.current_ws - tmp3.prev_ss - tmp2.prev_ws)
    / ((tmp3.prev_ss + tmp2.prev_ws) * c.price_change)
    AS decimal(10,10)
  ) AS cross_price_elasticity
FROM tmp1 c
JOIN tmp2
  ON c.i_item_id = tmp2.ws_item_id
JOIN tmp3
  ON c.i_item_id = tmp3.ss_item_id