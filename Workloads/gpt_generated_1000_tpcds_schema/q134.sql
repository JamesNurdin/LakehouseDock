WITH base AS (
    SELECT
        td.t_time_sk,
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        s.s_store_name,
        sr.sr_item_sk,
        i.i_item_id,
        i.i_class_id,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cp.cp_department,
        cp.cp_type,
        ca.ca_state,
        hd.hd_income_band_sk,
        p.p_promo_id,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        wp.wp_url,
        web.web_name
    FROM time_dim td
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE i.i_class_id = 14
      AND ca.ca_state = 'GA'
      AND cp.cp_type = 'monthly'
      AND ws.ws_net_paid > (SELECT MAX(ws2.ws_net_paid) FROM web_sales ws2) / 2
)
SELECT
    s_store_name,
    cp_department,
    w_warehouse_name,
    order_cnt,
    total_net_paid,
    avg_net_paid,
    total_return_amount,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num
FROM (
    SELECT
        s_store_name,
        cp_department,
        w_warehouse_name,
        COUNT(DISTINCT ws_order_number) AS order_cnt,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_net_paid) AS avg_net_paid,
        SUM(cr_return_amount) AS total_return_amount
    FROM base
    GROUP BY s_store_name, cp_department, w_warehouse_name
) agg
ORDER BY total_net_paid DESC
LIMIT 100
