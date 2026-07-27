WITH
    ss AS (
        SELECT *
        FROM store_sales
    ),
    ws AS (
        SELECT *
        FROM web_sales
    ),
    cr AS (
        SELECT *
        FROM catalog_returns
    )
SELECT
    i.i_category                         AS category,
    s.s_store_name                       AS store_name,
    COUNT(DISTINCT ss.ss_ticket_number)  AS store_sales_txns,
    SUM(ss.ss_net_paid)                  AS store_sales_net,
    COUNT(DISTINCT ws.ws_order_number)   AS web_sales_txns,
    SUM(ws.ws_net_paid)                  AS web_sales_net,
    COUNT(DISTINCT cr.cr_order_number)   AS catalog_returns_txns,
    SUM(cr.cr_return_amount)             AS catalog_returns_amount,
    CASE
        WHEN SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 200000 THEN 'High'
        ELSE 'Low'
    END                                 AS overall_sales_level
FROM
    ss
    JOIN item i                     ON ss.ss_item_sk = i.i_item_sk
    JOIN store s                    ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t_ss              ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN promotion p_ss             ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss     ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN inventory inv              ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse w_inv            ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    JOIN ws                        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t_ws              ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN promotion p_ws             ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm_ws            ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws             ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN web_site we                ON ws.ws_web_site_sk = we.web_site_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_bill      ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN customer_address ca_ws_ship      ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN cr                        ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t_cr             ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp           ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cr           ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN warehouse w_cr            ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
GROUP BY
    i.i_category,
    s.s_store_name
HAVING
    SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 50000
ORDER BY
    overall_sales_level DESC,
    store_sales_net DESC
LIMIT 100
