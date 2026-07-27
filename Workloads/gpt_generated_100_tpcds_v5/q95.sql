WITH sub_returns AS (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS net_amount,
        sm.sm_carrier,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_dep_count,
        wp.wp_type
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cr.cr_return_amount > 50.00
      AND hd.hd_dep_count BETWEEN 1 AND 4
      AND ib.ib_upper_bound <= 80000
      AND sm.sm_carrier = 'UPS'
      AND wp.wp_type = 'home'
),
sub_sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_net_paid_inc_tax AS net_amount,
        sm.sm_carrier,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_dep_count,
        wp.wp_type
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_net_paid_inc_tax > 1000.00
      AND hd.hd_dep_count BETWEEN 2 AND 5
      AND ib.ib_lower_bound >= 30000
      AND sm.sm_carrier = 'UPS'
      AND wp.wp_type = 'home'
)
SELECT
    order_number,
    net_amount,
    sm_carrier,
    ib_lower_bound,
    ib_upper_bound,
    hd_dep_count,
    wp_type,
    ROW_NUMBER() OVER (PARTITION BY sm_carrier ORDER BY net_amount DESC) AS rn
FROM (
    SELECT * FROM sub_returns
    UNION ALL
    SELECT * FROM sub_sales
) u
ORDER BY sm_carrier, rn
LIMIT 100
