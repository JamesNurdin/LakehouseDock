WITH sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        td.t_hour,
        SUM(ss.ss_net_profit) AS profit_sum,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_meal_time = 'dinner'
      AND td.t_sub_shift = 'evening'
      AND cd.cd_gender = 'F'
      AND cd.cd_education_status = '4 yr Degree'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 100000
    GROUP BY
        cd.cd_gender,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        td.t_hour
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    AVG(profit_sum) AS avg_profit_sum,
    SUM(sales_cnt) AS total_sales_cnt
FROM sales_agg
WHERE profit_sum > (
    SELECT AVG(ss2.ss_net_profit)
    FROM store_sales ss2
    JOIN time_dim td2 ON ss2.ss_sold_time_sk = td2.t_time_sk
    WHERE td2.t_meal_time = 'dinner'
)
GROUP BY ib_lower_bound, ib_upper_bound
HAVING AVG(profit_sum) > 5000
ORDER BY avg_profit_sum DESC
LIMIT 100
