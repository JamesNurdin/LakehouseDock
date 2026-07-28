WITH base_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        ss.ss_net_paid,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        sm_cat.sm_type          AS cat_ship_mode,
        w_cat.w_state           AS cat_warehouse_state,
        sm_ret.sm_type          AS ret_ship_mode,
        w_ret.w_state           AS ret_warehouse_state,
        ca_bill.ca_state       AS bill_state,
        ca_ship.ca_state       AS ship_state,
        cd_bill.cd_gender      AS bill_gender,
        cd_ship.cd_gender      AS ship_gender,
        ib_bill.ib_upper_bound AS bill_income_upper_bound,
        td_cs.t_hour            AS cs_hour,
        td_cr.t_hour            AS cr_hour,
        td_ss.t_hour            AS ss_hour,
        td_ws.t_hour            AS ws_hour,
        wp.wp_type             AS web_page_type,
        ws_site.web_name        AS web_site_name,
        p.p_discount_active    AS promo_discount_active
    FROM item i
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
       AND p.p_item_sk = i.i_item_sk
    /* Ship mode for catalog sales */
    JOIN ship_mode sm_cat
        ON cs.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
    /* Ship mode for returns (different role) */
    JOIN ship_mode sm_ret
        ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    /* Warehouse for catalog sales */
    JOIN warehouse w_cat
        ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
    /* Warehouse for returns (different role) */
    JOIN warehouse w_ret
        ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    /* Billing and shipping addresses for catalog sales */
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    /* Refund and returning addresses for returns (different roles) */
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_returner
        ON cr.cr_returning_addr_sk = ca_returner.ca_address_sk
    /* Customer demographics for billing and shipping */
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    /* Demographics for refunds and returning customers */
    JOIN customer_demographics cd_refund
        ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_demographics cd_returner
        ON cr.cr_returning_cdemo_sk = cd_returner.cd_demo_sk
    /* Household demographics for billing and shipping */
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    /* Household demographics for returns */
    JOIN household_demographics hd_refund
        ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN household_demographics hd_returner
        ON cr.cr_returning_hdemo_sk = hd_returner.hd_demo_sk
    /* Income band for billing household */
    JOIN income_band ib_bill
        ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    /* Time dimensions */
    JOIN time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN time_dim td_ss
        ON ss.ss_sold_time_sk = td_ss.t_time_sk
    JOIN time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
    /* Web related dimensions */
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
)
SELECT
    i_category,
    i_brand,
    cat_ship_mode,
    cat_warehouse_state,
    SUM(cs_net_paid)               AS total_catalog_net_paid,
    SUM(ss_net_paid)               AS total_store_net_paid,
    SUM(ws_net_paid)               AS total_web_net_paid,
    SUM(cr_return_amount)          AS total_return_amount,
    SUM(inv_quantity_on_hand)      AS total_inventory_qty,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper_bound
FROM base_sales
GROUP BY
    i_category,
    i_brand,
    cat_ship_mode,
    cat_warehouse_state
ORDER BY total_catalog_net_paid DESC
