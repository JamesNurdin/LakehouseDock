WITH joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        c.c_customer_id,
        c.c_birth_year,
        cd.cd_gender,
        ca.ca_state,
        cc.cc_call_center_id,
        cp.cp_type,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        i.inv_quantity_on_hand,
        t.t_am_pm,
        CASE WHEN cs.cs_sales_price > 500 THEN 'High' ELSE 'Low' END AS sale_category
    FROM
        store_sales ss
        JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_return_time_sk = t.t_time_sk
            AND sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_customer_sk = c.c_customer_sk
            AND sr.sr_cdemo_sk = cd.cd_demo_sk
            AND sr.sr_addr_sk = ca.ca_address_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = t.t_time_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
            AND cs.cs_bill_addr_sk = ca.ca_address_sk
            AND cs.cs_ship_customer_sk = c.c_customer_sk
            AND cs.cs_ship_cdemo_sk = cd.cd_demo_sk
            AND cs.cs_ship_addr_sk = ca.ca_address_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN inventory i
            ON i.inv_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_returns cr
            ON cr.cr_returned_time_sk = t.t_time_sk
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_refunded_customer_sk = c.c_customer_sk
            AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
            AND cr.cr_refunded_addr_sk = ca.ca_address_sk
            AND cr.cr_returning_customer_sk = c.c_customer_sk
            AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
            AND cr.cr_returning_addr_sk = ca.ca_address_sk
            AND cr.cr_call_center_sk = cc.cc_call_center_sk
            AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
            AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            AND cr.cr_warehouse_sk = w.w_warehouse_sk
            AND cr.cr_order_number = cs.cs_order_number
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = t.t_time_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_bill_addr_sk = ca.ca_address_sk
            AND ws.ws_ship_customer_sk = c.c_customer_sk
            AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_ship_addr_sk = ca.ca_address_sk
            AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
            AND ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_returns wr
            ON wr.wr_returned_time_sk = t.t_time_sk
            AND wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_refunded_customer_sk = c.c_customer_sk
            AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
            AND wr.wr_refunded_addr_sk = ca.ca_address_sk
            AND wr.wr_returning_customer_sk = c.c_customer_sk
            AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
            AND wr.wr_returning_addr_sk = ca.ca_address_sk
            AND wr.wr_order_number = ws.ws_order_number
    WHERE
        t.t_am_pm = 'PM'
        AND c.c_birth_year >= 1970
        AND w.w_state = 'CA'
),
customer_agg AS (
    SELECT
        c_customer_id,
        c_birth_year,
        ca_state,
        sale_category,
        SUM(ss_net_paid) AS total_store_net_paid,
        SUM(ss_net_paid_inc_tax) AS total_store_net_paid_inc_tax,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(sr_return_amt) AS total_store_return_amt,
        SUM(cs_net_paid) AS total_catalog_net_paid,
        SUM(cs_net_paid_inc_tax) AS total_catalog_net_paid_inc_tax,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(cr_return_amount) AS total_catalog_return_amt,
        SUM(ws_net_paid) AS total_web_net_paid,
        SUM(ws_net_paid_inc_tax) AS total_web_net_paid_inc_tax,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM joined
    GROUP BY
        c_customer_id,
        c_birth_year,
        ca_state,
        sale_category
)
SELECT
    ca_state,
    sale_category,
    AVG(total_store_net_paid) AS avg_store_net_paid,
    AVG(total_catalog_net_paid) AS avg_catalog_net_paid,
    AVG(total_web_net_paid) AS avg_web_net_paid,
    COUNT(*) AS customer_count
FROM customer_agg
WHERE total_store_net_paid > 1000
    AND total_catalog_net_paid > 500
    AND total_web_net_paid > 300
GROUP BY
    ca_state,
    sale_category
HAVING COUNT(*) >= 5
ORDER BY
    avg_store_net_paid DESC
LIMIT 100
