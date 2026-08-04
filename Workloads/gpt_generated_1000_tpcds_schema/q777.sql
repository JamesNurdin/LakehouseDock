WITH sampled_returns AS (
  SELECT *
  FROM catalog_returns
  TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_ship_cost,
    cr.cr_reversed_charge,
    cr.cr_warehouse_sk,
    cr.cr_refunded_customer_sk,
    w.w_city,
    w.w_state,
    c.c_birth_year,
    c.c_preferred_cust_flag
  FROM sampled_returns cr
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE w.w_state IN ('CA', 'TX')
    AND w.w_zip LIKE '44%'
    AND c.c_preferred_cust_flag = 'Y'
    AND cr.cr_return_amount > 100
),
-- LATERAL subquery to compute total ship cost for the warehouse
lateral_agg AS (
  SELECT
    jd.*, 
    la.total_ship_cost
  FROM joined_data jd
  LEFT JOIN LATERAL (
    SELECT SUM(cr2.cr_return_ship_cost) AS total_ship_cost
    FROM catalog_returns cr2
    WHERE cr2.cr_warehouse_sk = jd.cr_warehouse_sk
      AND cr2.cr_return_amount > 0
  ) la ON true
),
aggregated AS (
  SELECT
    w_city,
    w_state,
    c_birth_year,
    SUM(cr_return_amount) AS sum_return_amount,
    SUM(cr_return_ship_cost) AS sum_ship_cost,
    SUM(total_ship_cost) AS sum_total_ship_cost
  FROM lateral_agg
  GROUP BY GROUPING SETS (
    (w_city, w_state, c_birth_year),
    (w_state, c_birth_year),
    (c_birth_year)
  )
),
final_union AS (
  SELECT w_city, w_state, c_birth_year,
         sum_return_amount,
         sum_ship_cost,
         sum_total_ship_cost
  FROM aggregated
  WHERE sum_return_amount > 5000
  UNION
  SELECT w_city, w_state, c_birth_year,
         sum_return_amount,
         sum_ship_cost,
         sum_total_ship_cost
  FROM aggregated
  WHERE sum_ship_cost > 2000
)
SELECT w_city,
       w_state,
       c_birth_year,
       sum_return_amount,
       sum_ship_cost,
       sum_total_ship_cost
FROM final_union
ORDER BY sum_return_amount DESC, w_state
LIMIT 100
