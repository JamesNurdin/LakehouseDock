WITH
  base_fact AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_item_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk,
      cr.cr_ship_mode_sk,
      cr.cr_refunded_addr_sk,
      cr.cr_returning_addr_sk,
      cr.cr_refunded_hdemo_sk,
      cr.cr_returning_hdemo_sk,
      cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_return_quantity >= 1
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND cr.cr_ship_mode_sk IN (7, 9, 10)
  ),
  joined AS (
    SELECT
      cr.*, 
      d_return.d_year,
      i.i_category,
      i.i_current_price,
      cc.cc_company_name,
      cp.cp_type,
      sm.sm_ship_mode_id,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_addr_sk = cr.cr_returning_addr_sk
      ) AS addr_total_return_amount
    FROM base_fact cr
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  promo_join AS (
    SELECT
      p.p_promo_id,
      p.p_item_sk,
      p.p_cost,
      d_promo.d_year AS promo_year,
      i2.i_category AS promo_category
    FROM promotion p
    JOIN item i2 ON p.p_item_sk = i2.i_item_sk
    JOIN date_dim d_promo ON p.p_start_date_sk = d_promo.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_cost > 50
  ),
  full_outer AS (
    SELECT
      j.d_year,
      j.i_category,
      j.cr_return_amount,
      j.cc_company_name,
      j.cp_type,
      j.sm_ship_mode_id,
      j.hd_vehicle_count,
      j.addr_total_return_amount,
      pj.p_promo_id,
      pj.p_cost,
      pj.promo_year,
      pj.promo_category,
      CASE
        WHEN j.cr_return_amount > pj.p_cost THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
      END AS loss_category,
      j.cr_item_sk
    FROM joined j
    FULL OUTER JOIN promo_join pj
      ON j.cr_item_sk = pj.p_item_sk
  ),
  final_set AS (
    SELECT *
    FROM full_outer
    WHERE (hd_vehicle_count IS NOT NULL AND hd_vehicle_count > 1)
       OR (p_cost IS NOT NULL AND p_cost < 200)
  )
SELECT
  fs.d_year,
  fs.i_category,
  fs.cc_company_name,
  fs.cr_return_amount,
  fs.p_cost,
  fs.loss_category,
  ROW_NUMBER() OVER (PARTITION BY fs.cc_company_name ORDER BY fs.cr_return_amount DESC) AS rn,
  SUM(fs.cr_return_amount) OVER (PARTITION BY fs.d_year ORDER BY fs.cr_return_amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_return_sum
FROM final_set fs
INTERSECT
SELECT
  d_year,
  i_category,
  cc_company_name,
  cr_return_amount,
  p_cost,
  loss_category,
  ROW_NUMBER() OVER (PARTITION BY cc_company_name ORDER BY cr_return_amount DESC) AS rn,
  SUM(cr_return_amount) OVER (PARTITION BY d_year ORDER BY cr_return_amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_return_sum
FROM (
  SELECT
    j.d_year,
    j.i_category,
    j.cc_company_name,
    j.cr_return_amount,
    pj.p_cost,
    CASE
      WHEN j.cr_return_amount > pj.p_cost THEN 'HIGH_LOSS'
      ELSE 'LOW_LOSS'
    END AS loss_category
  FROM joined j
  LEFT JOIN promo_join pj ON j.cr_item_sk = pj.p_item_sk
  WHERE j.i_current_price BETWEEN 10 AND 1000
) sub
ORDER BY d_year DESC, cr_return_amount DESC
LIMIT 100
