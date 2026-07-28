WITH ranked_returns AS (
    SELECT
        c.c_customer_id,
        c.c_email_address,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        sm.sm_code,
        sm.sm_type,
        td.t_hour,
        td.t_am_pm,
        ca.ca_city,
        ca.ca_state,
        wp.wp_url,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY cr.cr_return_amount DESC) AS rn,
        SUM(cr.cr_return_amount) OVER (PARTITION BY sm.sm_code) AS total_return_by_mode,
        CASE WHEN cr.cr_return_amount > 500 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category
    FROM catalog_returns AS cr
    JOIN time_dim AS td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode AS sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer AS c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address AS ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN web_page AS wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
      AND c.c_birth_day BETWEEN 5 AND 20
      AND cr.cr_reversed_charge > 30
      AND cr.cr_return_amount > 100
      AND td.t_hour BETWEEN 9 AND 17
      AND wp.wp_url LIKE 'http%'
)
SELECT *
FROM ranked_returns
WHERE rn <= 5
ORDER BY sm_code, rn
