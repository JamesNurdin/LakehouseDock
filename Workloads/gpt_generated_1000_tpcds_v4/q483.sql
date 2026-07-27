WITH agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        w.w_warehouse_name,
        ws_site.web_name AS web_site_name,
        wp.wp_url,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        hd_bill.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_name,
        cp.cp_department,
        r_cr.r_reason_desc AS cr_reason_desc,
        st.s_store_name,
        sr.sr_net_loss,
        r_sr.r_reason_desc AS sr_reason_desc,
        i.inv_quantity_on_hand
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN tpcds.store st
        ON sr.sr_store_sk = st.s_store_sk
    JOIN tpcds.reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN tpcds.inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND w.w_city = 'San Francisco'
        AND cc.cc_class = 'medium'
        AND ib.ib_upper_bound >= 100000
    GROUP BY
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        w.w_warehouse_name,
        ws_site.web_name,
        wp.wp_url,
        ca_bill.ca_city,
        ca_ship.ca_city,
        hd_bill.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_name,
        cp.cp_department,
        r_cr.r_reason_desc,
        st.s_store_name,
        sr.sr_net_loss,
        r_sr.r_reason_desc,
        i.inv_quantity_on_hand
    HAVING
        SUM(ws.ws_quantity) > 10
)
SELECT DISTINCT
    agg.*, 
    RANK() OVER (PARTITION BY agg.ws_sold_date_sk ORDER BY agg.ws_net_profit DESC) AS profit_rank_by_date
FROM agg
ORDER BY agg.ws_sold_date_sk DESC, profit_rank_by_date ASC
LIMIT 100
