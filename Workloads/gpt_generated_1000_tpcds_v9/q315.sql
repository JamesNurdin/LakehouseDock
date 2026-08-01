WITH return_agg AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_birth_country,
        cc.cc_name AS call_center_name,
        cc.cc_state AS cc_state,
        sm.sm_type AS ship_mode_type,
        sm.sm_code AS ship_mode_code,
        td.t_hour AS hour,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_amount,
        SUM(cr.cr_return_tax) AS total_tax,
        SUM(cr.cr_return_amt_inc_tax) AS total_amt_inc_tax,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HIGH'
            WHEN SUM(cr.cr_return_amount) BETWEEN 500 AND 1000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS amount_category
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1990
      AND c.c_birth_country IN ('MEXICO', 'PHILIPPINES', 'FIJI')
      AND sm.sm_code IN ('AIR', 'SEA')
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
        cr.cr_returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_birth_country,
        cc.cc_name,
        cc.cc_state,
        sm.sm_type,
        sm.sm_code,
        td.t_hour
)
SELECT
    ca.customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    ca.c_birth_year,
    ca.c_birth_country,
    ca.call_center_name,
    ca.cc_state,
    ca.ship_mode_type,
    ca.ship_mode_code,
    ca.hour,
    ca.num_returns,
    ca.total_amount,
    ca.amount_category,
    AVG(ca.total_amount) OVER () AS avg_total_amount,
    (SELECT MAX(wp.wp_max_ad_count)
     FROM web_page wp
     WHERE wp.wp_customer_sk = ca.customer_sk) AS max_ad_count_per_customer
FROM (
    SELECT
        customer_sk,
        c_first_name,
        c_last_name,
        c_birth_year,
        c_birth_country,
        call_center_name,
        cc_state,
        ship_mode_type,
        ship_mode_code,
        hour,
        num_returns,
        total_amount,
        amount_category
    FROM return_agg
    WHERE amount_category = 'HIGH'
    UNION ALL
    SELECT
        customer_sk,
        c_first_name,
        c_last_name,
        c_birth_year,
        c_birth_country,
        call_center_name,
        cc_state,
        ship_mode_type,
        ship_mode_code,
        hour,
        num_returns,
        total_amount,
        amount_category
    FROM return_agg
    WHERE amount_category = 'LOW'
) AS ca
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_customer_sk = ca.customer_sk
      AND wp.wp_autogen_flag = 'Y'
      AND wp.wp_max_ad_count >= 2
)
ORDER BY ca.total_amount DESC
LIMIT 100
