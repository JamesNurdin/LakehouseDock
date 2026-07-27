WITH
  dim_time AS (
    SELECT t_time_sk, t_hour, t_am_pm
    FROM time_dim
    WHERE t_am_pm = 'PM'                     -- filter 1
  ),
  dim_household AS (
    SELECT hd_demo_sk, hd_income_band_sk, hd_vehicle_count, hd_dep_count
    FROM household_demographics
    WHERE hd_vehicle_count > 0               -- filter 2
  ),
  dim_income AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
  ),
  agg_returns AS (
    SELECT
      cc.cc_name,
      r.r_reason_desc,
      sm.sm_type,
      w.w_state,
      dt.t_hour,
      ib.ib_lower_bound,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN call_center cc               ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r                     ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm                 ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                  ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN dim_time dt                  ON cr.cr_returned_time_sk = dt.t_time_sk
    JOIN dim_household dh             ON cr.cr_refunded_hdemo_sk = dh.hd_demo_sk
    JOIN dim_income ib                ON dh.hd_income_band_sk = ib.ib_income_band_sk
    WHERE w.w_country = 'United States'    -- filter 3
    GROUP BY GROUPING SETS (
      (cc.cc_name, r.r_reason_desc, sm.sm_type, w.w_state, dt.t_hour, ib.ib_lower_bound),
      (cc.cc_name, r.r_reason_desc, sm.sm_type, w.w_state, dt.t_hour),
      (cc.cc_name, r.r_reason_desc, sm.sm_type, w.w_state),
      (cc.cc_name, r.r_reason_desc, sm.sm_type),
      (cc.cc_name, r.r_reason_desc),
      (cc.cc_name),
      ()
    )
  ),
  agg_sales AS (
    SELECT
      dt.t_hour,
      ib.ib_lower_bound,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS cnt_sales
    FROM store_sales ss
    JOIN dim_time dt               ON ss.ss_sold_time_sk = dt.t_time_sk
    JOIN dim_household dh          ON ss.ss_hdemo_sk = dh.hd_demo_sk
    JOIN dim_income ib             ON dh.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY dt.t_hour, ib.ib_lower_bound
  )
SELECT
  ar.cc_name,
  ar.r_reason_desc,
  ar.sm_type,
  ar.w_state,
  ar.t_hour,
  ar.ib_lower_bound,
  ar.total_return_amount,
  ar.cnt_returns,
  COALESCE(asales.total_sales, 0) AS total_sales,
  COALESCE(asales.cnt_sales, 0)   AS cnt_sales,
  CASE WHEN COALESCE(asales.total_sales, 0) = 0 THEN NULL
       ELSE ar.total_return_amount / asales.total_sales END AS return_to_sales_ratio
FROM agg_returns ar
LEFT JOIN agg_sales asales
  ON ar.t_hour = asales.t_hour
 AND (ar.ib_lower_bound = asales.ib_lower_bound OR ar.ib_lower_bound IS NULL)
WHERE ar.t_hour IS NOT NULL
ORDER BY ar.cc_name, ar.r_reason_desc, ar.t_hour DESC
LIMIT 100
