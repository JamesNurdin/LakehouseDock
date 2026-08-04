WITH base AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    r.r_reason_desc,
    cc.cc_city,
    w.w_state,
    cp.cp_department
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
),
filtered_a AS (
  SELECT
    cr_order_number,
    cr_return_amount,
    CONCAT(cc_city, '_', w_state) AS city_state,
    REGEXP_EXTRACT(r_reason_desc, '(\\w+) working', 1) AS extracted_word,
    cc_city,
    w_state,
    cp_department
  FROM base
  WHERE REGEXP_LIKE(r_reason_desc, '^Stopped')
    AND cc_city LIKE 'A%'
),
filtered_b AS (
  SELECT
    cr_order_number,
    cr_return_amount,
    CONCAT(cc_city, '_', w_state) AS city_state,
    REGEXP_EXTRACT(r_reason_desc, '(size)', 1) AS extracted_word,
    cc_city,
    w_state,
    cp_department
  FROM base
  WHERE REGEXP_LIKE(r_reason_desc, 'size')
    AND cc_city LIKE '%ville'
),
intersected AS (
  SELECT cr_order_number, cr_return_amount, city_state, cc_city, w_state, cp_department
  FROM filtered_a
  INTERSECT
  SELECT cr_order_number, cr_return_amount, city_state, cc_city, w_state, cp_department
  FROM filtered_b
),
unioned AS (
  SELECT cr_order_number FROM filtered_a
  UNION
  SELECT cr_order_number FROM filtered_b
),
excepted AS (
  SELECT cr_order_number FROM unioned
  EXCEPT
  SELECT cr_order_number FROM intersected
),
agg AS (
  SELECT
    cc_city,
    w_state,
    cp_department,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr_order_number) AS distinct_orders
  FROM base
  WHERE cr_order_number IN (SELECT cr_order_number FROM excepted)
  GROUP BY CUBE (cc_city, w_state, cp_department)
)
SELECT
  cc_city,
  w_state,
  cp_department,
  total_return_amount,
  distinct_orders,
  SUM(total_return_amount) OVER (PARTITION BY cc_city ORDER BY w_state
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_city_return
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
