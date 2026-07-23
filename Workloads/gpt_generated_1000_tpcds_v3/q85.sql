WITH all_data AS (
    SELECT
        d_ss.d_year AS year,
        i.i_brand AS brand,
        sm_ws.sm_code AS ship_mode_code,
        w_ws.w_state AS state,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid,
        cr.cr_return_amount AS catalog_return_amount,
        wr.wr_return_amt AS web_return_amount,
        inv.inv_quantity_on_hand AS inventory_qty
    FROM item i
    INNER JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    INNER JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    INNER JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN income_band ib
        ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    INNER JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    INNER JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    INNER JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    INNER JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    INNER JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    INNER JOIN date_dim d_we
        ON we.web_open_date_sk = d_we.d_date_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    INNER JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    INNER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN date_dim d_cc
        ON cc.cc_open_date_sk = d_cc.d_date_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN date_dim d_cp
        ON cp.cp_start_date_sk = d_cp.d_date_sk
    INNER JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    INNER JOIN warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    INNER JOIN household_demographics hd_cr
        ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    INNER JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    INNER JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    INNER JOIN household_demographics hd_wr
        ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    INNER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    INNER JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    INNER JOIN warehouse w_inv
        ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    INNER JOIN promotion p2
        ON p2.p_item_sk = i.i_item_sk
    INNER JOIN date_dim d_p
        ON p2.p_start_date_sk = d_p.d_date_sk
    WHERE d_ss.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND sm_ws.sm_code = 'AIR'
      AND w_ws.w_state = 'CA'
)
SELECT
    year,
    brand,
    ship_mode_code,
    state,
    SUM(store_net_paid) AS total_store_net_paid,
    SUM(web_net_paid) AS total_web_net_paid,
    SUM(catalog_return_amount) AS total_catalog_return_amount,
    SUM(web_return_amount) AS total_web_return_amount,
    SUM(inventory_qty) AS total_inventory_quantity,
    COUNT(*) AS transaction_count
FROM all_data
GROUP BY year, brand, ship_mode_code, state
ORDER BY total_store_net_paid DESC
LIMIT 100
