WITH base AS (
   SELECT
     cr.cr_returned_date_sk,
     cr.cr_return_quantity,
     cr.cr_return_amount,
     cr.cr_returning_customer_sk,
     cr.cr_returning_hdemo_sk,
     cr.cr_returning_addr_sk,
     cr.cr_call_center_sk,
     cr.cr_ship_mode_sk,
     cr.cr_warehouse_sk,
     cc.cc_state,
     ca.ca_state,
     w.w_state,
     sm.sm_type,
     hd.hd_buy_potential,
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     d_ret.d_year,
     s.s_store_id,
     s.s_state,
     ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_return_amount DESC) AS rn_store,
     LAG(cr.cr_return_amount) OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_return_amount DESC) AS lag_return_amount
   FROM tpcds.catalog_returns cr
   JOIN tpcds.date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN tpcds.customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
   JOIN tpcds.store s ON s.s_closed_date_sk = d_ret.d_date_sk
   WHERE d_ret.d_year BETWEEN 2000 AND 2002
     AND cc.cc_state = 'CA'
     AND ca.ca_state = 'CA'
     AND w.w_state = 'CA'
     AND sm.sm_type = 'AIR'
     AND hd.hd_buy_potential LIKE '%1000%'
     AND cr.cr_return_amount > 100
),
high_rank AS (
   SELECT cr_returning_customer_sk
   FROM base
   WHERE rn_store <= 5
),
high_amount AS (
   SELECT cr_returning_customer_sk
   FROM base
   WHERE cr_return_amount > 500
),
common_customers AS (
   SELECT cr_returning_customer_sk
   FROM high_rank
   INTERSECT
   SELECT cr_returning_customer_sk
   FROM high_amount
),
unioned AS (
   SELECT
     cr_returning_customer_sk,
     s_store_id,
     d_year,
     cr_return_amount
   FROM base
   WHERE cr_return_quantity >= 2
   UNION DISTINCT
   SELECT
     cr_returning_customer_sk,
     s_store_id,
     d_year,
     cr_return_amount
   FROM base
   WHERE cr_return_quantity = 1
)
SELECT
  u.s_store_id,
  u.d_year,
  SUM(u.cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT u.cr_returning_customer_sk) AS distinct_customers,
  SUM(CASE WHEN u.cr_returning_customer_sk IN (SELECT cr_returning_customer_sk FROM common_customers) THEN 1 ELSE 0 END) AS common_customer_count
FROM unioned u
GROUP BY GROUPING SETS (
  (u.s_store_id, u.d_year),
  (u.s_store_id),
  (u.d_year)
)
ORDER BY total_return_amount DESC
LIMIT 100
