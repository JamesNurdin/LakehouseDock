WITH cte_aggregated AS (
    SELECT
        cr.cr_returned_date_sk,
        cc.cc_call_center_id,
        cc.cc_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        t_ret.t_hour,
        hd_return.hd_buy_potential,
        cc.cc_hours,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT c_return.c_customer_id) AS distinct_customers
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN customer c_return
        ON cr.cr_returning_customer_sk = c_return.c_customer_sk
    JOIN household_demographics hd_return
        ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    WHERE d_ret.d_year = 2022
      AND t_ret.t_hour BETWEEN 9 AND 18
      AND cc.cc_state = 'CA'
      AND hd_return.hd_vehicle_count >= 2
      AND hd_return.hd_buy_potential = '5001-10000'
      AND cr.cr_return_amount > 0
    GROUP BY
        cr.cr_returned_date_sk,
        cc.cc_call_center_id,
        cc.cc_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        t_ret.t_hour,
        hd_return.hd_buy_potential,
        cc.cc_hours
)
SELECT
    cc_call_center_id,
    cc_state,
    d_year,
    t_hour,
    hd_buy_potential,
    hour_segment,
    SUM(sum_return_amount) AS total_return_amount,
    AVG(avg_return_quantity) AS overall_avg_return_quantity,
    SUM(distinct_customers) AS total_distinct_customers
FROM (
    SELECT
        *,
        split(cc_hours, '-') AS hour_parts
    FROM cte_aggregated
) sub
CROSS JOIN UNNEST(hour_parts) AS u(hour_segment)
GROUP BY
    cc_call_center_id,
    cc_state,
    d_year,
    t_hour,
    hd_buy_potential,
    hour_segment
HAVING SUM(sum_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
