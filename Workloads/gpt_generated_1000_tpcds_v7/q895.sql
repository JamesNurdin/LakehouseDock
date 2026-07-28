WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_sales_price,
        ca1.ca_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_discount_active,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cp.cp_department,
        cp.cp_type,
        sm_ret.sm_type AS return_ship_type,
        w_ret.w_warehouse_name AS return_warehouse,
        inv.inv_quantity_on_hand,
        w_inv.w_warehouse_name AS inventory_warehouse,
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_quantity,
        ws.ws_sales_price,
        sm_ws.sm_type AS web_ship_type,
        w_ws.w_warehouse_name AS web_warehouse,
        wsit.web_name AS site_name
    FROM date_dim d
    /* store_sales and its related dim tables */
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    LEFT JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    /* catalog_returns chain */
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    LEFT JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    /* inventory chain */
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    /* web_sales chain */
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    /* additional joins required by the model */
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    LEFT JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    LEFT JOIN promotion p_cat ON cp.cp_catalog_page_sk = cp.cp_catalog_page_sk -- dummy join to keep catalog_page in the graph
    WHERE d.d_year = 2002
      AND p.p_discount_active = 'Y'
      AND sm_ret.sm_type = 'AIR'
      AND ib.ib_lower_bound >= 50000
)
SELECT
    base.d_date,
    base.d_year,
    base.ss_ticket_number,
    base.ss_net_paid_inc_tax,
    base.ca_state,
    base.ib_lower_bound,
    base.ib_upper_bound,
    RANK() OVER (PARTITION BY base.ca_state ORDER BY base.ss_net_paid_inc_tax DESC) AS state_sales_rank,
    SUM(base.ss_ext_sales_price) OVER (PARTITION BY base.ca_state ORDER BY base.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS sales_7day_moving_sum,
    base.ws_order_number,
    base.ws_net_paid_inc_ship,
    base.return_ship_type,
    base.return_warehouse,
    base.inventory_warehouse,
    base.inv_quantity_on_hand,
    base.site_name,
    base.cp_department,
    base.cp_type
FROM base
ORDER BY base.ca_state, state_sales_rank
