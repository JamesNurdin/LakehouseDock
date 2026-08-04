WITH joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_country,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_country,
        cc.cc_rec_start_date,
        cp.cp_catalog_page_sk,
        cp.cp_department,
        sm.sm_ship_mode_sk,
        sm.sm_type AS ship_type,
        w.w_warehouse_sk,
        w.w_state,
        r.r_reason_sk,
        r.r_reason_desc,
        ss.ss_quantity AS store_quantity,
        ss.ss_net_paid AS store_net_paid,
        s.s_store_sk,
        s.s_state AS store_state,
        ws.ws_quantity AS web_quantity,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_web_site_sk,
        we.web_site_sk,
        we.web_rec_start_date,
        we.web_manager
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
       AND ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cc.cc_country = 'United States'
      AND ca.ca_state = 'CA'
      AND hd.hd_vehicle_count >= 1
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND we.web_rec_start_date >= DATE '2000-01-01'
),
reason_avg AS (
    SELECT
        j.*, 
        lt.avg_return_by_reason
    FROM joined j
    CROSS JOIN LATERAL (
        SELECT AVG(cr2.cr_return_amount) AS avg_return_by_reason
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = j.r_reason_sk
    ) lt
)
SELECT
    ca_state,
    cp_department,
    SUM(return_amount) AS total_return_amount,
    SUM(net_loss) AS total_net_loss,
    COUNT(DISTINCT cs_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT ca_address_sk) AS distinct_customers,
    SUM(CASE WHEN return_amount > 100 THEN 1 ELSE 0 END) AS high_value_returns,
    AVG(avg_return_by_reason) AS avg_return_by_reason_over_group
FROM (
    SELECT
        ca.ca_state AS ca_state,
        cp.cp_department AS cp_department,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        cs.cs_item_sk,
        ca.ca_address_sk,
        ra.avg_return_by_reason
    FROM reason_avg ra
    JOIN catalog_returns cr ON cr.cr_order_number = ra.cr_order_number
    JOIN catalog_sales cs ON cs.cs_order_number = cr.cr_order_number
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
) sub
GROUP BY ROLLUP (ca_state, cp_department)
ORDER BY ca_state, cp_department
LIMIT 100
