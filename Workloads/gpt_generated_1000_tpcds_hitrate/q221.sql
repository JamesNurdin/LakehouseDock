WITH sales_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        d.d_year,
        i.i_category,
        cd.cd_gender,
        hd.hd_buy_potential,
        ca.ca_state,
        p.p_promo_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT
    d_year,
    i_category,
    cd_gender,
    hd_buy_potential,
    SUM(sales_amt) AS total_sales,
    SUM(qty) AS total_quantity,
    AVG(discount_amt) AS avg_discount
FROM (
    SELECT
        sb.d_year,
        sb.i_category,
        sb.cd_gender,
        sb.hd_buy_potential,
        sb.ss_net_paid AS sales_amt,
        sb.ss_quantity AS qty,
        sb.ss_ext_discount_amt AS discount_amt,
        sr.sr_ticket_number,
        d_ret.d_date_sk AS ret_date_sk,
        cr.cr_returned_date_sk,
        cp.cp_description,
        cc.cc_name,
        r.r_reason_desc,
        ws.ws_order_number,
        wsite.web_site_id,
        sm.sm_type,
        wh.w_warehouse_name
    FROM sales_base sb
    /* store returns */
    JOIN store_returns sr ON sr.sr_ticket_number = sb.ss_ticket_number
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    /* catalog returns */
    JOIN catalog_returns cr ON cr.cr_item_sk = sb.ss_item_sk
    JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    /* web sales */
    JOIN web_sales ws ON ws.ws_item_sk = sb.ss_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE sb.ss_ticket_number NOT IN (SELECT sr_ticket_number FROM store_returns)
) t
GROUP BY CUBE (d_year, i_category, cd_gender, hd_buy_potential)
ORDER BY total_sales DESC
LIMIT 100
