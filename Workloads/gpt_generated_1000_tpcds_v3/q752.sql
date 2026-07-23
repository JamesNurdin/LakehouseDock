WITH agg AS (
    SELECT
        d_sold.d_year AS d_year,
        cc.cc_name AS cc_name,
        w.w_warehouse_name AS w_warehouse_name,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN tpcds.date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN tpcds.customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN tpcds.customer_demographics cd_refund
        ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    LEFT JOIN tpcds.customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    LEFT JOIN tpcds.date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN tpcds.time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    LEFT JOIN tpcds.warehouse w_return
        ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
    LEFT JOIN tpcds.ship_mode sm_return
        ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
    LEFT JOIN tpcds.call_center cc_return
        ON cr.cr_call_center_sk = cc_return.cc_call_center_sk
    LEFT JOIN tpcds.catalog_page cp_return
        ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.date_dim d_inventory
        ON inv.inv_date_sk = d_inventory.d_date_sk
    LEFT JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    LEFT JOIN tpcds.date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    LEFT JOIN tpcds.date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    LEFT JOIN tpcds.date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN tpcds.date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND d_ship.d_year = 2001
        AND i.i_current_price BETWEEN 20 AND 500
        AND cc.cc_state = 'CA'
        AND w.w_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND ws.web_country = 'United States'
        AND cd_bill.cd_gender = 'M'
        AND cd_ship.cd_gender = 'F'
    GROUP BY
        d_sold.d_year,
        cc.cc_name,
        w.w_warehouse_name,
        i.i_item_id,
        i.i_product_name
)
SELECT
    d_year,
    cc_name,
    w_warehouse_name,
    i_item_id,
    i_product_name,
    total_sales_amount,
    total_return_amount,
    (total_sales_profit - total_return_loss) AS net_profit,
    CASE WHEN (total_sales_profit - total_return_loss) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_status,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_sales_profit - total_return_loss) DESC) AS profit_rank
FROM agg
ORDER BY net_profit DESC
LIMIT 100
