WITH joined_data AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        cc.cc_rec_end_date,
        p.p_promo_name,
        p.p_discount_active,
        cd.cd_gender,
        sm.sm_type,
        td.t_hour,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship_tax AS catalog_sales_amount,
        cr.cr_net_loss AS return_loss,
        ws.ws_net_paid_inc_ship_tax AS web_sales_amount
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_sales ws
        ON ws.ws_order_number = cs.cs_order_number
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_rec_end_date = DATE '2000-12-31'
      AND cd.cd_gender = 'M'
      AND sm.sm_type = 'AIR'
      AND cs.cs_net_paid_inc_ship_tax > 3000
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 8 AND 18
)
SELECT
    cc_name,
    p_promo_name,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    SUM(return_loss) AS total_return_loss,
    SUM(web_sales_amount) AS total_web_sales,
    COUNT(*) AS txn_count
FROM joined_data
GROUP BY GROUPING SETS (
    (cc_name, p_promo_name),
    (cc_name),
    (p_promo_name),
    ()
)
HAVING SUM(catalog_sales_amount) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
