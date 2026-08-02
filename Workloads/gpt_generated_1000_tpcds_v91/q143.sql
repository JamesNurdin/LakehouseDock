/* Goal: Compute profit and loss metrics per item, web site, ship mode, and warehouse by combining store sales, web sales, catalog returns, and web returns, rank items by total profit, and retain all web sites even without sales. */
WITH aggregated AS (
    SELECT
        i_ws.i_item_id,
        i_ws.i_product_name,
        ws_site.web_name,
        sm_ws.sm_type,
        w_ws.w_warehouse_name,
        SUM(ss.ss_net_profit)               AS total_store_profit,
        SUM(ws.ws_net_profit)               AS total_web_profit,
        SUM(cr.cr_net_loss)                 AS total_catalog_return_loss,
        SUM(wr.wr_net_loss)                AS total_web_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    RIGHT OUTER JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i_ws
        ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i_ws.i_item_sk
       AND ss.ss_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i_ws.i_item_sk
       AND cr.cr_returned_time_sk = t_ws.t_time_sk
    LEFT JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN customer_address ca_cr_refunded
        ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
    LEFT JOIN customer_demographics cd_cr_refunded
        ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i_ws.i_item_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN item i_wr
        ON wr.wr_item_sk = i_wr.i_item_sk
    LEFT JOIN customer_address ca_wr_refunded
        ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    LEFT JOIN customer_demographics cd_wr_refunded
        ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN customer_address ca_wr_returning
        ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    LEFT JOIN customer_demographics cd_wr_returning
        ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i_ws.i_item_sk
          AND cr2.cr_returned_date_sk = ss.ss_sold_date_sk
          AND cr2.cr_net_loss > 0
    )
    GROUP BY
        i_ws.i_item_id,
        i_ws.i_product_name,
        ws_site.web_name,
        sm_ws.sm_type,
        w_ws.w_warehouse_name
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.web_name,
    a.sm_type,
    a.w_warehouse_name,
    a.total_store_profit,
    a.total_web_profit,
    a.total_catalog_return_loss,
    a.total_web_return_loss,
    a.store_transactions,
    a.web_orders,
    ROW_NUMBER() OVER (PARTITION BY a.i_item_id ORDER BY (a.total_store_profit + a.total_web_profit) DESC) AS profit_rank
FROM aggregated a
ORDER BY (a.total_store_profit + a.total_web_profit) DESC
LIMIT 100
