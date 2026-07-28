WITH hourly_sales AS (
    SELECT
        td.t_hour AS hour,
        td.t_meal_time AS meal_time,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_coupon_amt) AS total_coupon,
        COUNT(*) AS tx_count
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_net_paid_inc_tax > 100
      AND ss.ss_coupon_amt >= 0
      AND ss.ss_promo_sk BETWEEN 1 AND 1500
      AND ss.ss_quantity >= 1
      AND td.t_minute IN (1, 6, 11, 7, 2)
    GROUP BY td.t_hour, td.t_meal_time
),
filtered_sales AS (
    SELECT
        hour,
        meal_time,
        total_net_paid,
        total_coupon,
        tx_count,
        CASE
            WHEN total_coupon > 500 THEN 'high'
            ELSE 'low'
        END AS coupon_category,
        AVG(total_net_paid) OVER (PARTITION BY hour) AS avg_net_per_hour,
        ROW_NUMBER() OVER (PARTITION BY hour ORDER BY total_net_paid DESC) AS rn
    FROM hourly_sales hs
    WHERE total_net_paid > 200
      AND EXISTS (
          SELECT 1
          FROM store_sales s2
          JOIN time_dim t2
              ON s2.ss_sold_time_sk = t2.t_time_sk
          WHERE t2.t_hour = hs.hour
            AND s2.ss_store_sk = 5
      )
)
SELECT
    hour,
    meal_time,
    total_net_paid,
    total_coupon,
    tx_count,
    coupon_category,
    avg_net_per_hour,
    rn
FROM filtered_sales
WHERE rn <= 10
ORDER BY hour ASC, total_net_paid DESC
LIMIT 100
