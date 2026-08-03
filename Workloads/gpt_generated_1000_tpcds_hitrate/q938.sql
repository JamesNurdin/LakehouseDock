WITH cr_agg AS (
   SELECT
       cr.cr_warehouse_sk,
       cr.cr_ship_mode_sk,
       cr.cr_refunded_hdemo_sk,
       cr.cr_returned_date_sk,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_return_quantity) AS total_qty,
       COUNT(*) AS cnt
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
     AND cr.cr_return_amount > 100
   GROUP BY cr.cr_warehouse_sk, cr.cr_ship_mode_sk, cr.cr_refunded_hdemo_sk, cr.cr_returned_date_sk
),
joined AS (
   SELECT
       w.w_warehouse_id,
       w.w_state,
       sm.sm_type,
       d2.d_month_seq,
       ib.ib_upper_bound,
       CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
       cr_agg.total_return_amount,
       cr_agg.total_qty,
       hd.hd_demo_sk,
       p.p_cost,
       wp.wp_autogen_flag,
       ws.web_country
   FROM cr_agg
   RIGHT JOIN warehouse w ON cr_agg.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN ship_mode sm ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN household_demographics hd ON cr_agg.cr_refunded_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN date_dim d2 ON cr_agg.cr_returned_date_sk = d2.d_date_sk
   LEFT JOIN promotion p ON d2.d_date_sk = p.p_start_date_sk
   LEFT JOIN web_page wp ON d2.d_date_sk = wp.wp_creation_date_sk
   LEFT JOIN web_site ws ON d2.d_date_sk = ws.web_open_date_sk
   WHERE sm.sm_type = 'AIR'
     AND w.w_state = 'CA'
     AND ib.ib_upper_bound > 50000
     AND p.p_discount_active = 'Y'
     AND wp.wp_autogen_flag = 'Y'
     AND ws.web_country = 'United States'
),
final_rank AS (
   SELECT
       w_warehouse_id,
       w_state,
       sm_type,
       d_month_seq,
       income_category,
       SUM(total_return_amount) AS sum_return_amount,
       SUM(total_qty) AS sum_return_qty,
       COUNT(*) AS grp_cnt,
       COUNT(DISTINCT hd_demo_sk) AS distinct_hd_demo,
       SUM(p_cost) AS total_promo_cost,
       ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY SUM(total_return_amount) DESC) AS rk
   FROM joined
   GROUP BY w_warehouse_id, w_state, sm_type, d_month_seq, income_category, ib_upper_bound
   HAVING SUM(total_return_amount) > 1000
)
SELECT *
FROM final_rank
WHERE rk <= 5
ORDER BY sum_return_amount DESC
LIMIT 100
