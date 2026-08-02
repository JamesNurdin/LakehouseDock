WITH sales_returns AS (
    SELECT 
        cp.cp_department,
        sm.sm_type,
        r.r_reason_desc,
        d_sales.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return,
        SUM(cs.cs_net_profit) AS total_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
        CASE WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w_ship ON cs.cs_warehouse_sk = w_ship.w_warehouse_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
    LEFT JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    LEFT JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    LEFT JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    LEFT JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    LEFT JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    WHERE cs.cs_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = cs.cs_item_sk
            AND inv.inv_date_sk = cs.cs_sold_date_sk
      )
    GROUP BY cp.cp_department, sm.sm_type, r.r_reason_desc, d_sales.d_year
    HAVING SUM(cs.cs_ext_sales_price) > 1000
),
inv_web AS (
    SELECT 
        d_inv.d_date AS inv_date,
        w_inv.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        wp_sub.wp_url,
        wp_sub.wp_type
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    FULL OUTER JOIN (
        SELECT 
            wp.wp_web_page_sk,
            wp.wp_url,
            wp.wp_type,
            d_wp.d_date AS wp_date
        FROM web_page wp
        JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
    ) wp_sub
        ON d_inv.d_date = wp_sub.wp_date
    GROUP BY d_inv.d_date, w_inv.w_warehouse_name, wp_sub.wp_url, wp_sub.wp_type
),
web_returns_agg AS (
    SELECT 
        d_wr.d_year,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        COUNT(*) AS web_return_count
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    GROUP BY d_wr.d_year, wp.wp_type
)
SELECT 
    sr.cp_department,
    sr.sm_type,
    sr.r_reason_desc,
    sr.d_year,
    sr.total_sales,
    sr.total_return,
    sr.total_profit,
    sr.total_return_loss,
    sr.profit_status,
    iw.total_on_hand,
    iw.w_warehouse_name,
    iw.wp_url,
    iw.wp_type,
    wra.total_web_return_amt,
    wra.total_web_net_loss,
    wra.web_return_count
FROM sales_returns sr
LEFT JOIN inv_web iw
    ON year(iw.inv_date) = sr.d_year
LEFT JOIN web_returns_agg wra
    ON wra.d_year = sr.d_year
    AND wra.wp_type = iw.wp_type
ORDER BY sr.total_sales DESC
LIMIT 100
