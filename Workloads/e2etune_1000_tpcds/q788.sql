WITH base AS (
    SELECT
        cc.cc_state,
        cd.cd_education_status,
        hd.hd_buy_potential,
        td.t_meal_time,
        SUM(cc.cc_employees) AS total_employees,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        COUNT(*) AS row_cnt
    FROM call_center cc
    JOIN time_dim td ON cc.cc_open_date_sk = td.t_time_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = td.t_time_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wp.wp_customer_sk = cd.cd_demo_sk
    JOIN reason r ON r.r_reason_sk = cc.cc_division
    WHERE cc.cc_state IN ('TN', 'LA', 'GA')
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'High'
      AND td.t_hour BETWEEN 9 AND 17
      AND r.r_reason_id = 'R001'
    GROUP BY
        cc.cc_state,
        cd.cd_education_status,
        hd.hd_buy_potential,
        td.t_meal_time
    HAVING COUNT(*) > 10
)
SELECT
    base.*, 
    RANK() OVER (PARTITION BY base.cc_state ORDER BY base.avg_purchase_estimate DESC) AS purchase_rank
FROM base
ORDER BY base.avg_purchase_estimate DESC
LIMIT 100
