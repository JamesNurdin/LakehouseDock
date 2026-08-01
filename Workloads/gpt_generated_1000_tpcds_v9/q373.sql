WITH ws_agg AS (
   SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      d.d_year AS d_year,
      SUM(ws.ws_net_paid) AS total_net_paid,
      AVG(ws.ws_ext_discount_amt) AS avg_discount,
      COUNT(*) AS order_cnt,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_paid) DESC) AS ranking_year
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
     AND t.t_meal_time = 'lunch'
     AND w.w_city = 'Fairview'
     AND p.p_discount_active = 'Y'
   GROUP BY ws.ws_bill_customer_sk, d.d_year
),
cr_agg AS (
   SELECT
      cr.cr_refunded_customer_sk AS customer_sk,
      d.d_year AS d_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      AVG(cr.cr_fee) AS avg_fee,
      COUNT(*) AS return_cnt,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS ranking_year
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 2001
     AND t.t_meal_time = 'lunch'
     AND cc.cc_state = 'CA'
     AND cp.cp_type = 'monthly'
   GROUP BY cr.cr_refunded_customer_sk, d.d_year
),
combined AS (
   SELECT
      customer_sk,
      d_year,
      total_net_paid AS metric_amount,
      order_cnt AS metric_count,
      ranking_year
   FROM ws_agg
   UNION
   SELECT
      customer_sk,
      d_year,
      total_return_amount AS metric_amount,
      return_cnt AS metric_count,
      ranking_year
   FROM cr_agg
),
filtered_combined AS (
   SELECT
      customer_sk,
      d_year,
      metric_amount,
      metric_count,
      ranking_year
   FROM combined
   WHERE metric_amount > 1000
),
final_set AS (
   SELECT
      customer_sk,
      d_year,
      SUM(metric_amount) AS sum_metric_amount,
      SUM(metric_count) AS sum_metric_count,
      MAX(ranking_year) AS max_ranking
   FROM filtered_combined
   GROUP BY customer_sk, d_year
)
SELECT
   res.customer_sk,
   res.d_year,
   res.sum_metric_amount,
   res.sum_metric_count,
   res.max_ranking,
   (SELECT MAX(p_cost) FROM promotion) AS max_promo_cost
FROM (
   SELECT
      customer_sk,
      d_year,
      sum_metric_amount,
      sum_metric_count,
      max_ranking
   FROM final_set
   WHERE customer_sk IN (
      SELECT c.c_customer_sk
      FROM customer c
      WHERE c.c_birth_country = 'United States'
   )
   EXCEPT
   SELECT
      customer_sk,
      d_year,
      sum_metric_amount,
      sum_metric_count,
      max_ranking
   FROM final_set
   WHERE d_year = 2000
) AS res
ORDER BY res.sum_metric_amount DESC, res.d_year
