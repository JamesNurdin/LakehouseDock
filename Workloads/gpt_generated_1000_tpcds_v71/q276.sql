WITH joined_data AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        td.t_hour,
        cs.cs_net_paid AS catalog_net_paid,
        ws.ws_net_paid AS web_net_paid,
        cr.cr_return_amount AS catalog_return_amount,
        sr.sr_return_amt AS store_return_amount,
        cd.cd_gender,
        hd.hd_buy_potential,
        i.i_brand,
        r_cr.r_reason_desc AS catalog_return_reason,
        r_sr.r_reason_desc AS store_return_reason
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_return_time_sk = td.t_time_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND i.i_current_price > 100
      AND s.s_city = 'Sycamore'
)
SELECT
    s_store_id,
    s_store_name,
    call_center_name,
    ship_mode_type,
    t_hour,
    SUM(COALESCE(catalog_net_paid, 0) + COALESCE(web_net_paid, 0)) AS total_net_paid,
    SUM(COALESCE(catalog_return_amount, 0) + COALESCE(store_return_amount, 0)) AS total_return_amount,
    COUNT(*) AS transaction_count,
    AVG(CASE WHEN catalog_return_amount IS NOT NULL THEN 1 ELSE 0 END) AS catalog_return_rate
FROM joined_data
GROUP BY s_store_id, s_store_name, call_center_name, ship_mode_type, t_hour
HAVING SUM(COALESCE(catalog_net_paid, 0) + COALESCE(web_net_paid, 0)) > 10000
   AND SUM(COALESCE(catalog_return_amount, 0) + COALESCE(store_return_amount, 0)) < 5000
   AND COUNT(*) >= 10
ORDER BY total_net_paid DESC
LIMIT 100
