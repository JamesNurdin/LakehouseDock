WITH
  /* Filtered catalog returns with date and warehouse filters */
  filtered_returns AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_warehouse_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_fee,
      cr.cr_order_number,
      d.d_year,
      d.d_holiday,
      d.d_following_holiday,
      d.d_same_day_lq,
      w.w_warehouse_name,
      w.w_warehouse_sk,
      w.w_street_name
    FROM
      tpcds.catalog_returns AS cr
      INNER JOIN tpcds.date_dim AS d
        ON cr.cr_returned_date_sk = d.d_date_sk
      INNER JOIN tpcds.warehouse AS w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
      d.d_holiday = 'N'                     -- predicate 1
      AND d.d_following_holiday = 'N'        -- predicate 2
      AND d.d_same_day_lq = 2414938          -- predicate 3
      AND cr.cr_returning_cdemo_sk IN (1129703, 1405170)  -- predicate 4
      AND cr.cr_returned_time_sk BETWEEN 40000 AND 70000   -- predicate 5
      AND w.w_street_name LIKE '%Elm%'      -- predicate 6
  ),

  /* Sampled warehouse rows */
  warehouse_sample AS (
    SELECT *
    FROM tpcds.warehouse
    TABLESAMPLE BERNOULLI (20)
  ),

  /* Sampled inventory rows */
  inventory_sample AS (
    SELECT *
    FROM tpcds.inventory
    TABLESAMPLE BERNOULLI (10)
  ),

  /* Join filtered returns with the sampled inventory (chain topology) */
  joined AS (
    SELECT
      fr.cr_return_quantity,
      fr.cr_return_amount,
      fr.cr_return_tax,
      fr.cr_fee,
      fr.cr_order_number,
      fr.d_year,
      fr.w_warehouse_name,
      fr.w_warehouse_sk
    FROM
      filtered_returns AS fr
      INNER JOIN inventory_sample AS i
        ON i.inv_date_sk = fr.cr_returned_date_sk
        AND i.inv_warehouse_sk = fr.w_warehouse_sk
  ),

  /* Aggregation per year and warehouse */
  aggregated AS (
    SELECT
      d_year,
      w_warehouse_name,
      SUM(cr_return_amount) AS total_return_amount,
      AVG(cr_return_tax)   AS avg_tax,
      COUNT(*)             AS cnt_returns,
      MIN(cr_return_quantity) AS min_quantity,
      MAX(cr_fee)          AS max_fee
    FROM joined
    GROUP BY d_year, w_warehouse_name
  ),

  /* Two sub‑queries whose key sets will be intersected */
  warehouse_keys_a AS (
    SELECT w_warehouse_sk FROM tpcds.warehouse WHERE w_street_name LIKE '%Elm%'
  ),
  warehouse_keys_b AS (
    SELECT w_warehouse_sk FROM tpcds.warehouse WHERE w_city = 'San Jose'
  ),
  intersect_keys AS (
    SELECT w_warehouse_sk FROM warehouse_keys_a
    INTERSECT
    SELECT w_warehouse_sk FROM warehouse_keys_b
  ),

  /* Two sub‑queries whose key sets will be subtracted (EXCEPT) */
  warehouse_keys_c AS (
    SELECT w_warehouse_sk FROM tpcds.warehouse WHERE w_state = 'CA'
  ),
  warehouse_keys_d AS (
    SELECT w_warehouse_sk FROM tpcds.warehouse WHERE w_gmt_offset > 0
  ),
  except_keys AS (
    SELECT w_warehouse_sk FROM warehouse_keys_c
    EXCEPT
    SELECT w_warehouse_sk FROM warehouse_keys_d
  ),

  /* Create an array column and expand it with UNNEST */
  returns_with_array AS (
    SELECT
      cr_order_number,
      ARRAY[cr_return_amount, cr_fee] AS amounts
    FROM tpcds.catalog_returns
    WHERE cr_return_amount IS NOT NULL
  ),
  unnested AS (
    SELECT
      cr_order_number,
      amt
    FROM returns_with_array
    CROSS JOIN UNNEST(amounts) AS t(amt)
  ),

  /* Scalar totals from the UNNESTed data – used only to satisfy the UNNEST requirement */
  unnested_totals AS (
    SELECT
      SUM(amt) AS sum_unnested_amount,
      COUNT(*) AS cnt_unnested_rows
    FROM unnested
  )

SELECT
  a.d_year,
  a.w_warehouse_name,
  a.total_return_amount,
  a.avg_tax,
  a.cnt_returns,
  a.min_quantity,
  a.max_fee,
  -- list of intersected warehouse keys as an array (could be empty)
  ARRAY_AGG(DISTINCT ik.w_warehouse_sk) AS intersect_warehouse_keys,
  -- list of keys that survive the EXCEPT operation
  ARRAY_AGG(DISTINCT ek.w_warehouse_sk) AS except_warehouse_keys,
  -- values derived from the UNNEST example (same for every row)
  ut.sum_unnested_amount,
  ut.cnt_unnested_rows
FROM
  aggregated AS a
  LEFT JOIN intersect_keys AS ik ON 1 = 1
  LEFT JOIN except_keys   AS ek ON 1 = 1
  CROSS JOIN unnested_totals AS ut
GROUP BY
  a.d_year,
  a.w_warehouse_name,
  a.total_return_amount,
  a.avg_tax,
  a.cnt_returns,
  a.min_quantity,
  a.max_fee,
  ut.sum_unnested_amount,
  ut.cnt_unnested_rows
ORDER BY
  a.d_year,
  a.w_warehouse_name
