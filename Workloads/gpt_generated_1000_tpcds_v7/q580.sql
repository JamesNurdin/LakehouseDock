WITH sales_agg AS (
    SELECT
        td.t_hour AS hour,
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_net,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_promo_sk IN (754, 370, 1061)
      AND ss.ss_net_paid_inc_tax > 1000
      AND ss.ss_coupon_amt BETWEEN 10 AND 500
      AND td.t_hour BETWEEN 8 AND 20
      AND td.t_time >= 5
      AND td.t_meal_time = 'Lunch'
    GROUP BY td.t_hour, ss.ss_promo_sk
)
SELECT
    hour,
    AVG(total_net) AS avg_net_per_promo,
    SUM(total_sales) AS sum_sales_all_promos,
    COUNT(*) AS promo_count
FROM sales_agg
WHERE total_sales > 5000
GROUP BY hour
HAVING COUNT(*) >= 2
ORDER BY hour
