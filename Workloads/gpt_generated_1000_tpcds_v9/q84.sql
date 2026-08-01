WITH base_data AS (
    SELECT
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        d.d_year AS d_year,
        p.p_promo_name AS p_promo_name,
        p.p_discount_active AS p_discount_active,
        cp.cp_department AS cp_department,
        r_sr.r_reason_desc AS r_reason_desc,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_net_loss AS wr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        c_ss.c_customer_id AS c_customer_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
        AND s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_start_date_sk = d.d_date_sk
        AND p.p_end_date_sk = d.d_date_sk
    JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    -- Store Returns
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    -- Catalog Returns
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c_cr_refunded ON cr.cr_refunded_customer_sk = c_cr_refunded.c_customer_sk
    JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
    JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
    JOIN customer c_cr_returning ON cr.cr_returning_customer_sk = c_cr_returning.c_customer_sk
    JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
    JOIN customer_address ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cp.cp_start_date_sk = d.d_date_sk
        AND cp.cp_end_date_sk = d.d_date_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    -- Inventory (linked to the same warehouse)
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    -- Web Sales
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_ship_date_sk = d.d_date_sk
    JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        AND p_ws.p_start_date_sk = d.d_date_sk
        AND p_ws.p_end_date_sk = d.d_date_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    -- Web Returns
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND inv.inv_quantity_on_hand > 1000
        AND r_sr.r_reason_desc = 'Wrong size'
)
SELECT
    s_store_name,
    s_state,
    d_year,
    p_promo_name,
    cp_department,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(ss_net_profit) AS total_store_net_profit,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(ws_net_profit) AS total_web_net_profit,
    SUM(wr_net_loss) AS total_web_return_loss,
    SUM(cr_net_loss) AS total_catalog_return_loss,
    SUM(inv_quantity_on_hand) AS total_inventory_quantity
FROM base_data
GROUP BY s_store_name, s_state, d_year, p_promo_name, cp_department
HAVING SUM(ss_net_profit) > 10000
ORDER BY total_store_net_profit DESC
LIMIT 100
