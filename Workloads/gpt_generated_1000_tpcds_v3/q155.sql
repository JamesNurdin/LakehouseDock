WITH per_ship_reason AS (
    SELECT
        sm.sm_type,
        r_sr.r_reason_desc AS reason_desc,
        SUM(ws.ws_net_profit) AS sum_net_profit,
        SUM(sr.sr_return_amt) AS sum_store_return_amt,
        SUM(cr.cr_return_amount) AS sum_catalog_return_amt,
        SUM(wr.wr_return_amt) AS sum_web_return_amt,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    WHERE
        sm.sm_type = 'AIR'
        AND cc.cc_country = 'United States'
        AND c.c_preferred_cust_flag = 'Y'
        AND ws.ws_net_paid_inc_ship_tax > 1000
        AND wp.wp_link_count >= 10
        AND hd.hd_income_band_sk BETWEEN 5 AND 10
        AND ws.ws_quantity >= 2
        AND (r_sr.r_reason_desc LIKE '%damage%' OR r_cr.r_reason_desc LIKE '%damage%' OR r_wr.r_reason_desc LIKE '%damage%')
    GROUP BY
        sm.sm_type,
        r_sr.r_reason_desc
)
SELECT
    sm_type,
    SUM(sum_net_profit) AS total_net_profit,
    SUM(sum_store_return_amt) AS total_store_return_amt,
    SUM(sum_catalog_return_amt) AS total_catalog_return_amt,
    SUM(sum_web_return_amt) AS total_web_return_amt,
    SUM(order_cnt) AS total_orders,
    SUM(sum_net_profit) / NULLIF(SUM(order_cnt), 0) AS avg_net_profit_per_order
FROM per_ship_reason
GROUP BY sm_type
HAVING SUM(sum_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
