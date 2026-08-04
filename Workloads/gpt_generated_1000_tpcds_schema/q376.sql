WITH
  union_set AS (
    SELECT cr.cr_warehouse_sk AS warehouse_sk,
           cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 2000
    UNION
    SELECT cr.cr_warehouse_sk,
           cr.cr_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 5
  ),
  intersect_set AS (
    SELECT warehouse_sk
    FROM union_set
    WHERE return_amount > 3000
    INTERSECT
    SELECT w.w_warehouse_sk
    FROM warehouse w
    WHERE w.w_gmt_offset > -5
  ),
  base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_warehouse_sk,
      cr.cr_ship_mode_sk,
      cr.cr_reversed_charge,
      d.d_year,
      d.d_month_seq,
      sm.sm_type,
      w.w_state,
      w.w_warehouse_name,
      ws.web_site_id,
      i.inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    JOIN inventory i
      ON i.inv_date_sk = d.d_date_sk
     AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND i.inv_quantity_on_hand > 0
  )
SELECT
  b.cr_warehouse_sk,
  w.w_warehouse_name,
  b.d_year,
  SUM(b.cr_return_amount) AS total_return_amount,
  COUNT(*) AS return_cnt,
  CASE
    WHEN SUM(b.cr_return_amount) > (SELECT avg(cr_return_amount) FROM catalog_returns) THEN 'ABOVE_AVG'
    ELSE 'BELOW_AVG'
  END AS return_category,
  RANK() OVER (PARTITION BY b.d_year ORDER BY SUM(b.cr_return_amount) DESC) AS yearly_warehouse_rank,
  ROW_NUMBER() OVER (ORDER BY SUM(b.cr_return_amount) DESC) AS overall_rank
FROM base b
JOIN warehouse w
  ON b.cr_warehouse_sk = w.w_warehouse_sk
WHERE b.cr_warehouse_sk IN (SELECT warehouse_sk FROM intersect_set)
GROUP BY
  b.cr_warehouse_sk,
  w.w_warehouse_name,
  b.d_year
ORDER BY total_return_amount DESC
LIMIT 100
