WITH returns_daily AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_returned_time_sk,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_return_amt_inc_tax,
       d.d_date,
       d.d_year,
       t.t_time,
       t.t_meal_time,
       hd_ret.hd_buy_potential AS returning_buy_potential,
       hd_ret.hd_vehicle_count AS returning_vehicle_count,
       hd_ref.hd_buy_potential AS refunded_buy_potential,
       hd_ref.hd_vehicle_count AS refunded_vehicle_count,
       s.s_store_id,
       s.s_state,
       wp.wp_type,
       wp.wp_url
   FROM catalog_returns cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t
     ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN household_demographics hd_ret
     ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
   JOIN household_demographics hd_ref
     ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN store s
     ON s.s_closed_date_sk = d.d_date_sk
   JOIN web_page wp
     ON wp.wp_creation_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND t.t_meal_time = 'dinner'
     AND hd_ret.hd_vehicle_count >= 1
     AND cr.cr_net_loss > 500
     AND s.s_state = 'CA'
     AND wp.wp_type = 'customer'
),
avg_year_loss AS (
   SELECT d.d_year, AVG(cr.cr_net_loss) AS avg_net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   GROUP BY d.d_year
),
store_ranked AS (
   SELECT
       r.s_store_id,
       r.d_date,
       r.d_year,
       r.cr_net_loss,
       SUM(r.cr_net_loss) OVER (PARTITION BY r.s_store_id ORDER BY r.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_loss,
       ROW_NUMBER() OVER (PARTITION BY r.s_store_id ORDER BY r.cr_net_loss DESC) AS loss_rank,
       CASE
           WHEN r.cr_net_loss > 5000 THEN 'Very High'
           WHEN r.cr_net_loss > 1000 THEN 'High'
           WHEN r.cr_net_loss > 500 THEN 'Medium'
           ELSE 'Low'
       END AS loss_category
   FROM returns_daily r
),
high_loss_stores AS (
   SELECT DISTINCT s_store_id
   FROM store_ranked
   WHERE loss_category = 'Very High'
),
union_select AS (
   SELECT s_store_id, d_date, cr_net_loss
   FROM returns_daily
   WHERE cr_net_loss > 4000
   UNION ALL
   SELECT s_store_id, d_date, cr_net_loss
   FROM returns_daily
   WHERE cr_net_loss BETWEEN 3000 AND 4000
)
SELECT
   sr.s_store_id,
   sr.d_date,
   sr.cr_net_loss,
   sr.cumulative_loss,
   sr.loss_rank,
   sr.loss_category,
   ay.avg_net_loss,
   (SELECT AVG(cr.cr_net_loss) FROM catalog_returns cr) AS overall_avg_loss,
   CASE WHEN EXISTS (SELECT 1 FROM high_loss_stores hls WHERE hls.s_store_id = sr.s_store_id) THEN 1 ELSE 0 END AS is_top_very_high
FROM store_ranked sr
JOIN avg_year_loss ay ON ay.d_year = sr.d_year
WHERE sr.s_store_id IN (SELECT s_store_id FROM union_select)
ORDER BY sr.cumulative_loss DESC
LIMIT 100
