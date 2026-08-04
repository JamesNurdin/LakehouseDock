WITH ws_array AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ARRAY[ws.ws_quantity, ws.ws_sales_price] AS metrics,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk
    FROM web_sales ws
)
SELECT
    cc.cc_call_center_id,
    cs.cs_order_number,
    cr.cr_return_amount,
    sm1.sm_carrier AS cr_ship_carrier,
    sm2.sm_carrier AS ws_ship_carrier,
    hd1.hd_income_band_sk AS cs_income_band,
    hd2.hd_income_band_sk AS ss_income_band,
    wp.wp_url,
    wsite.web_name,
    SUM(ws_array.ws_sales_price) AS total_ws_sales,
    COUNT(DISTINCT ws_array.ws_order_number) AS distinct_ws_orders,
    metric_val,
    cross_set.dummy
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN ship_mode sm1
    ON sm1.sm_ship_mode_sk = cr.cr_ship_mode_sk
JOIN time_dim td
    ON td.t_time_sk = cs.cs_sold_time_sk
JOIN household_demographics hd1
    ON hd1.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN household_demographics hd2
    ON hd2.hd_demo_sk = ss.ss_hdemo_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN ws_array
    ON ws_array.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm2
    ON sm2.sm_ship_mode_sk = ws_array.ws_ship_mode_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws_array.ws_web_page_sk
JOIN web_site wsite
    ON wsite.web_site_sk = ws_array.ws_web_site_sk
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2) AS cross_set
CROSS JOIN UNNEST(ws_array.metrics) AS t(metric_val)
WHERE cs.cs_quantity > (SELECT MAX(ws_quantity) FROM web_sales)
GROUP BY
    cc.cc_call_center_id,
    cs.cs_order_number,
    cr.cr_return_amount,
    sm1.sm_carrier,
    sm2.sm_carrier,
    hd1.hd_income_band_sk,
    hd2.hd_income_band_sk,
    wp.wp_url,
    wsite.web_name,
    metric_val,
    cross_set.dummy
ORDER BY total_ws_sales DESC
LIMIT 100
