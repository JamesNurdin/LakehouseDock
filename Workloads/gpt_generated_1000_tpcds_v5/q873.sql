WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_type,
        sm.sm_carrier,
        td.t_meal_time,
        td.t_hour,
        ca_refunded.ca_location_type AS refunded_loc_type,
        ca_returning.ca_location_type AS returning_loc_type,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE td.t_meal_time = 'dinner'
      AND td.t_hour >= 10
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
      AND ca_refunded.ca_location_type = 'apartment'
      AND r.r_reason_sk = 5
      AND cr.cr_return_amount > 0
),
agg1 AS (
    SELECT
        sm_type,
        t_meal_time,
        COUNT(*) AS cnt_returns,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_quantity) AS avg_return_qty
    FROM joined
    GROUP BY sm_type, t_meal_time
)
SELECT
    sm_type,
    t_meal_time,
    cnt_returns,
    total_return_amount,
    avg_return_qty,
    (SELECT AVG(total_return_amount) FROM agg1) AS overall_avg_return_amount
FROM agg1
WHERE total_return_amount > (SELECT AVG(total_return_amount) FROM agg1)
ORDER BY total_return_amount DESC
LIMIT 100
