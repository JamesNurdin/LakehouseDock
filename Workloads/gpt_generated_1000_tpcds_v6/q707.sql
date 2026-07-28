WITH filtered_returns AS (
    SELECT cr.cr_return_amount,
           cr.cr_return_quantity,
           cr.cr_return_amt_inc_tax,
           i.i_item_id,
           i.i_current_price,
           i.i_class_id,
           i.i_class,
           sm.sm_type,
           hd.hd_income_band_sk,
           ib.ib_upper_bound,
           ib.ib_lower_bound
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
      ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_return_quantity >= 1
      AND i.i_current_price BETWEEN 50 AND 500
      AND ib.ib_upper_bound >= 60000
      AND sm.sm_type = 'AIR'
      AND i.i_class_id IN (3, 4, 5)
),
aggregated AS (
    SELECT i_class,
           SUM(cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt,
           AVG(cr_return_quantity) AS avg_qty,
           MAX(cr_return_amt_inc_tax) AS max_inc_tax,
           (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return
    FROM filtered_returns
    GROUP BY i_class
)
SELECT i_class,
       total_return_amount,
       return_cnt,
       avg_qty,
       max_inc_tax,
       overall_avg_return,
       RANK() OVER (ORDER BY total_return_amount DESC) AS revenue_rank,
       CASE
           WHEN total_return_amount > overall_avg_return * 2 THEN 'High'
           WHEN total_return_amount > overall_avg_return THEN 'Medium'
           ELSE 'Low'
       END AS performance_category
FROM aggregated
ORDER BY revenue_rank
LIMIT 100
