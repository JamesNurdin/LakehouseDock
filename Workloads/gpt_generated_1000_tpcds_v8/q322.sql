WITH return_metrics AS (
    SELECT s.s_store_id,
           SUM(sr.sr_net_loss) AS loss_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 40000
      AND ib.ib_upper_bound <= 90000
    GROUP BY s.s_store_id
),
sales_metrics AS (
    SELECT s.s_store_id,
           SUM(ss.ss_net_profit) AS profit_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 40000
      AND ib.ib_upper_bound <= 90000
    GROUP BY s.s_store_id
),
union_set AS (
    SELECT rm.s_store_id,
           rm.loss_amount AS metric_amount,
           'return' AS src
    FROM return_metrics rm
    UNION
    SELECT sm.s_store_id,
           sm.profit_amount AS metric_amount,
           'sale' AS src
    FROM sales_metrics sm
),
high_promo_stores AS (
    SELECT DISTINCT s.s_store_id
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND ss.ss_quantity > 5
),
intersected_stores AS (
    SELECT us.s_store_id
    FROM union_set us
    INTERSECT
    SELECT hps.s_store_id
    FROM high_promo_stores hps
)
SELECT us.s_store_id,
       s.s_city,
       s.s_state,
       us.metric_amount,
       us.src
FROM union_set us
JOIN store s ON us.s_store_id = s.s_store_id
WHERE us.s_store_id IN (SELECT s_store_id FROM intersected_stores)
ORDER BY us.metric_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
