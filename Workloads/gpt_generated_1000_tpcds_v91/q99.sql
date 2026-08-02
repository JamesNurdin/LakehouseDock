WITH cs_join AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cc.cc_state,
        cc.cc_country,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        t.t_hour,
        cd.cd_gender,
        sm.sm_carrier,
        w.w_state,
        w.w_city,
        i.i_color,
        i.i_brand,
        p.p_discount_active
    FROM
        catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        cc.cc_state = 'CA'
        AND i.i_color = 'Red'
        AND sm.sm_carrier = 'USPS'
        AND p.p_discount_active = 'Y'
        AND cc.cc_rec_start_date >= DATE '2000-01-01'
),

ws_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        wp.wp_type,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        w2.w_state AS ws_warehouse_state,
        w2.w_city AS ws_warehouse_city,
        i2.i_brand,
        i2.i_color,
        sm2.sm_carrier,
        p2.p_discount_active,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        ws.ws_sold_date_sk,
        web_s.web_rec_start_date,
        i2.i_rec_start_date
    FROM
        web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
        JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
        JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
        JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site web_s ON ws.ws_web_site_sk = web_s.web_site_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                   AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i2.i_item_sk
                                 AND inv.inv_warehouse_sk = w2.w_warehouse_sk
    WHERE
        wp.wp_type = 'A'
        AND web_s.web_country = 'United States'
        AND sm2.sm_carrier = 'USPS'
        AND r.r_reason_desc = 'Customer Not Satisfied'
        AND web_s.web_rec_start_date >= DATE '2000-01-01'
),

common_orders AS (
    SELECT cs_order_number AS order_number FROM cs_join
    INTERSECT
    SELECT ws_order_number AS order_number FROM ws_join
),

full_joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cc_state,
        cs.cc_country,
        cs.cp_catalog_number,
        cs.cp_catalog_page_number,
        cs.t_hour,
        cs.cd_gender,
        cs.sm_carrier,
        cs.w_state,
        cs.w_city,
        cs.i_color,
        cs.i_brand,
        cs.p_discount_active,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.wp_type,
        ws.wr_return_quantity,
        ws.wr_net_loss,
        ws.ws_warehouse_state,
        ws.ws_warehouse_city,
        ws.i_brand AS ws_i_brand,
        ws.i_color AS ws_i_color,
        ws.sm_carrier AS ws_sm_carrier,
        ws.p_discount_active AS ws_p_discount_active,
        ws.r_reason_desc,
        ws.inv_quantity_on_hand
    FROM cs_join cs
    FULL OUTER JOIN ws_join ws
        ON cs.cs_order_number = ws.ws_order_number
    WHERE (cs.cs_order_number IN (SELECT order_number FROM common_orders)
           OR ws.ws_order_number IN (SELECT order_number FROM common_orders))
)

SELECT
    cc_state,
    ws_warehouse_state,
    SUM(cs_net_paid) AS total_cs_net_paid,
    SUM(ws_net_paid) AS total_ws_net_paid,
    COUNT(*) AS row_count,
    MIN(cs_ext_sales_price) AS min_cs_ext_sales_price,
    MAX(ws_ext_sales_price) AS max_ws_ext_sales_price
FROM full_joined
GROUP BY GROUPING SETS (
    (cc_state, ws_warehouse_state),
    (cc_state),
    (ws_warehouse_state),
    ()
)
ORDER BY
    cc_state ASC NULLS LAST,
    ws_warehouse_state ASC NULLS LAST,
    total_cs_net_paid DESC
