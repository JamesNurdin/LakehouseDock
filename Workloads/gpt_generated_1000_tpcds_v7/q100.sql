WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_net_paid,
        s.s_state,
        i.i_category,
        td.t_time_sk
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
)
SELECT
    s.s_state,
    i.i_category,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
FROM base ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
-- Catalog Returns and its related dimensions
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
-- Refunded and Returning customers for Catalog Returns (using aliases)
LEFT JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
LEFT JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
LEFT JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
LEFT JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
LEFT JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
-- Web Returns and its related dimensions
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN customer c_wr_refunded
    ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
LEFT JOIN customer c_wr_returning
    ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
LEFT JOIN customer_demographics cd_wr_refunded
    ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_wr_returning
    ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
LEFT JOIN customer_address ca_wr_refunded
    ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
LEFT JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
-- Inventory (joins to both item and warehouse)
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY
    s.s_state,
    i.i_category
ORDER BY
    total_sales DESC
LIMIT 100
