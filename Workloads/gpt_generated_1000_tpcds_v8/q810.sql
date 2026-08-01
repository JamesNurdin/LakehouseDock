WITH
  /* Web side – joins to web_page, ship_mode and time_dim */
  web_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ship_mode_sk,
      ws.ws_web_page_sk,
      ws.ws_sold_time_sk,
      ws.ws_ext_sales_price,
      ws.ws_quantity,
      wp.wp_type,
      sm.sm_type AS ship_type,
      td.t_sub_shift
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_sold_time_sk IN (44795, 51596, 70397)                    -- predicate 1
      AND ws.ws_ext_sales_price > 1000                                   -- predicate 2
      AND wp.wp_type IS NOT NULL                                         -- predicate 3
      AND sm.sm_type = 'AIR'                                             -- predicate 4
      AND td.t_sub_shift = 'morning'                                     -- predicate 5
  ),

  /* Catalog side – joins to catalog_page, ship_mode, time_dim and call_center */
  catalog_base AS (
    SELECT
      cr.cr_order_number,
      cr.cr_ship_mode_sk,
      cr.cr_catalog_page_sk,
      cr.cr_returned_time_sk,
      cr.cr_return_amount,
      cp.cp_type,
      sm2.sm_type AS ship_type,
      td2.t_sub_shift
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN time_dim td2 ON cr.cr_returned_time_sk = td2.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cp.cp_type = 'quarterly'                                       -- predicate 6
      AND cr.cr_return_amount > 0                                        -- predicate 7
      AND sm2.sm_type = 'AIR'                                            -- predicate 8
      AND td2.t_sub_shift = 'morning'                                    -- predicate 9
      AND cc.cc_state = 'CA'                                             -- predicate 10
  ),

  /* Union of the two streams – set operation */
  union_set AS (
    SELECT
      ws_order_number AS order_id,
      ship_type,
      wp_type,
      ws_ext_sales_price AS amount
    FROM web_base
    UNION ALL
    SELECT
      cr_order_number AS order_id,
      ship_type,
      cp_type AS wp_type,
      cr_return_amount AS amount
    FROM catalog_base
  ),

  /* Orders that appear only in the union (i.e., not present in the pure web side) – EXCEPT */
  filtered_excepts AS (
    SELECT order_id FROM union_set
    EXCEPT
    SELECT ws_order_number AS order_id FROM web_base
  ),

  /* Aggregation with GROUPING SETS on shipping mode and page type */
  final_agg AS (
    SELECT
      ship_type,
      wp_type,
      SUM(amount) AS total_amount,
      COUNT(*) AS cnt
    FROM union_set u
    WHERE u.order_id IN (SELECT order_id FROM filtered_excepts)
    GROUP BY GROUPING SETS ((ship_type, wp_type), (ship_type))
  )

SELECT
  f.ship_type,
  f.wp_type,
  f.total_amount,
  f.cnt,
  l.bonus
FROM final_agg f
CROSS JOIN LATERAL (
  SELECT f.total_amount * 0.05 AS bonus
) AS l
WHERE f.total_amount > 5000                                            -- additional filter
ORDER BY f.total_amount DESC
LIMIT 100
