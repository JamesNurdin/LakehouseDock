WITH base AS (
    SELECT DISTINCT
        t.t_time_sk,
        t.t_hour,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        c.c_customer_sk,
        cd.cd_gender,
        ca.ca_state,
        r.r_reason_desc,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        cc.cc_name AS call_center_name,
        cp.cp_department,
        wp.wp_url,
        web.web_site_id,
        sr.sr_return_quantity,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand
    FROM time_dim t
    LEFT JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN item i ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = sr.sr_cdemo_sk
    LEFT JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
    LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    LEFT JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN web_site web ON web.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE
        t.t_hour BETWEEN 8 AND 12
        AND i.i_current_price > 100
        AND r.r_reason_desc LIKE '%damaged%'
),
agg AS (
    SELECT
        t_hour,
        ship_mode_type,
        cp_department,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(sr_return_quantity) AS total_store_return_qty,
        SUM(cr_return_quantity) AS total_catalog_return_qty,
        SUM(wr_return_quantity) AS total_web_return_qty,
        AVG(i_current_price) AS avg_item_price,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers
    FROM base
    GROUP BY ROLLUP (t_hour, ship_mode_type, cp_department)
)
SELECT
    t_hour,
    ship_mode_type,
    cp_department,
    total_net_paid,
    total_store_return_qty,
    total_catalog_return_qty,
    total_web_return_qty,
    avg_item_price,
    distinct_customers
FROM agg
WHERE
    total_net_paid > 10000
    OR total_store_return_qty > 500
    OR distinct_customers > 100
ORDER BY total_net_paid DESC NULLS LAST, t_hour, ship_mode_type
LIMIT 100
