WITH
  base AS (
    SELECT
      cr.cr_returned_date_sk,
      d.d_date,
      cr.cr_returned_time_sk,
      t.t_hour,
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cp.cp_department,
      sm.sm_type,
      w.w_warehouse_name,
      s.s_store_name,
      CASE WHEN cr.cr_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND t.t_hour BETWEEN 9 AND 17
      AND sm.sm_type = 'OVERNIGHT'
      AND w.w_country = 'United States'
      AND cp.cp_department = 'Electronics'
      AND cr.cr_return_quantity > 0
  ),
  filtered AS (
    SELECT
      cr_returned_date_sk,
      d_date,
      cr_returned_time_sk,
      t_hour,
      cr_order_number,
      cr_return_amount,
      cr_return_quantity,
      cp_department,
      sm_type,
      w_warehouse_name,
      s_store_name,
      amount_category
    FROM base
    WHERE cr_return_amount > 1500
  )
SELECT
  b.cr_returned_date_sk,
  b.d_date,
  b.cr_order_number,
  b.amount_category,
  b.cr_return_amount,
  b.cr_return_quantity,
  b.cp_department,
  b.sm_type,
  b.w_warehouse_name,
  b.s_store_name,
  ROW_NUMBER() OVER (PARTITION BY b.w_warehouse_name ORDER BY b.cr_return_amount DESC) AS warehouse_return_rank
FROM (
  SELECT * FROM base
  EXCEPT
  SELECT * FROM filtered
) AS b
ORDER BY warehouse_return_rank
LIMIT 100
