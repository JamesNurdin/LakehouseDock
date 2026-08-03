WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_ship_mode_sk,
        cr.cr_catalog_page_sk,
        cr.cr_returning_hdemo_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        td.t_meal_time,
        td.t_hour,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_return_quantity >= 1
      AND cp.cp_department = 'Electronics'
      AND sm.sm_carrier = 'UPS'
      AND td.t_meal_time = 'dinner'
),
agg AS (
    SELECT
        j.cp_department,
        j.cp_catalog_number,
        j.sm_ship_mode_id,
        j.t_meal_time,
        j.hd_dep_count,
        metric,
        SUM(value) AS sum_value,
        AVG(value) AS avg_value,
        COUNT(*) AS cnt,
        MIN(value) AS min_value,
        MAX(value) AS max_value
    FROM joined j
    CROSS JOIN UNNEST(ARRAY['return_amount','return_tax']) AS t(metric)
    CROSS JOIN LATERAL (
        SELECT CASE t.metric
                 WHEN 'return_amount' THEN j.cr_return_amount
                 WHEN 'return_tax'    THEN j.cr_return_tax
               END AS value
    ) v
    GROUP BY
        j.cp_department,
        j.cp_catalog_number,
        j.sm_ship_mode_id,
        j.t_meal_time,
        j.hd_dep_count,
        metric
)
SELECT
    ROW_NUMBER() OVER (ORDER BY sum_value DESC) AS row_num,
    cp_department,
    cp_catalog_number,
    sm_ship_mode_id,
    t_meal_time,
    hd_dep_count,
    metric,
    sum_value,
    avg_value,
    cnt,
    min_value,
    max_value
FROM agg
ORDER BY sum_value DESC
LIMIT 100
