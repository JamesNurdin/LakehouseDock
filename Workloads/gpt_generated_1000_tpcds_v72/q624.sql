WITH sales_data AS (
    SELECT
        cc.cc_state AS cc_state,
        i.i_brand AS i_brand,
        cd.cd_gender AS cd_gender,
        sm.sm_type AS sm_type,
        s.s_city AS s_city,
        wp.wp_type AS wp_type,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_quantity AS cs_quantity,
        cs.cs_order_number AS cs_order_number,
        cr.cr_return_amount AS cr_return_amount,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        td.t_hour AS t_hour
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE cd.cd_purchase_estimate >= 5000
      AND i.i_brand = 'Brand#23'
      AND cc.cc_state = 'CA'
      AND s.s_state = 'TX'
      AND td.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_amount > 100
)
SELECT
    cc_state,
    i_brand,
    cd_gender,
    sm_type,
    s_city,
    wp_type,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_quantity) AS avg_quantity,
    SUM(CASE WHEN cd_gender = 'M' THEN cs_net_paid ELSE 0 END) AS male_net_paid,
    SUM(CASE WHEN sr_net_loss > 0 THEN sr_net_loss ELSE 0 END) AS total_store_loss,
    SUM(CASE WHEN wr_net_loss > 0 THEN wr_net_loss ELSE 0 END) AS total_web_loss,
    MIN(t_hour) AS earliest_hour,
    MAX(t_hour) AS latest_hour
FROM sales_data
GROUP BY
    cc_state,
    i_brand,
    cd_gender,
    sm_type,
    s_city,
    wp_type
HAVING SUM(cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
