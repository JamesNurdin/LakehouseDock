WITH joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        r.r_reason_desc,
        sm_cr.sm_carrier,
        td.t_meal_time,
        hd_ret.hd_income_band_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        ws.ws_net_paid,
        ws.ws_quantity,
        wp.wp_type,
        wsite.web_name
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_cs
        ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
)
SELECT
    r_reason_desc AS reason_desc,
    sm_carrier AS carrier,
    t_meal_time AS meal_time,
    hd_income_band_sk AS income_band,
    SUM(cr_net_loss) AS sum_loss,
    SUM(ws_net_paid) AS sum_paid,
    COUNT(*) AS transaction_cnt,
    AVG(ws_net_paid) AS avg_paid
FROM joined
WHERE
    sm_carrier IN ('DIAMOND', 'USPS')
    AND t_meal_time = 'lunch'
    AND hd_income_band_sk BETWEEN 3 AND 7
    AND cr_net_loss > 0
    AND ws_net_paid > 0
    AND ws_net_paid > (SELECT AVG(cr_net_loss) FROM catalog_returns WHERE cr_reason_sk = 5)
GROUP BY
    r_reason_desc,
    sm_carrier,
    t_meal_time,
    hd_income_band_sk
HAVING
    SUM(cr_net_loss) > 1000
ORDER BY
    sum_loss DESC,
    avg_paid ASC
LIMIT 100
