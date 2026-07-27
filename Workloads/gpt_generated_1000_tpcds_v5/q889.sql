WITH
    cr AS (
        SELECT *
        FROM catalog_returns
    ),
    wr AS (
        SELECT *
        FROM web_returns
    )
SELECT
    cc.cc_name,
    sm.sm_type,
    cd_refunded.cd_gender,
    hd_refunded.hd_income_band_sk,
    i.i_brand,
    SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_order_number END) AS high_value_return_orders,
    CASE
        WHEN SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 10000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS loss_category
FROM cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN wr
    ON cr.cr_item_sk = wr.wr_item_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c_wp
    ON wp.wp_customer_sk = c_wp.c_customer_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
GROUP BY
    cc.cc_name,
    sm.sm_type,
    cd_refunded.cd_gender,
    hd_refunded.hd_income_band_sk,
    i.i_brand
ORDER BY total_net_loss DESC
LIMIT 100
