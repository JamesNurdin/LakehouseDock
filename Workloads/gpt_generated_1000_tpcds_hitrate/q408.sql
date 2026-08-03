(
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        w.w_warehouse_name,
        sm.sm_ship_mode_id,
        t.t_hour,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        (
            SELECT COUNT(*)
            FROM reason r_sub
            WHERE r_sub.r_reason_desc = 'Damaged'
        ) AS total_damaged_reason_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    WHERE i.i_brand = 'Brand#12'
      AND i.i_color = 'Red'
      AND w.w_state = 'CA'
      AND cd_bill.cd_gender = 'F'
      AND t.t_hour = 14
      AND sm.sm_contract = '5FKNB0j8aaqTB'
      AND sr.sr_customer_sk IN (
          SELECT c_customer_sk
          FROM customer
          WHERE c_preferred_cust_flag = 'Y'
      )
    GROUP BY
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        w.w_warehouse_name,
        sm.sm_ship_mode_id,
        t.t_hour
)
UNION DISTINCT
(
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        w.w_warehouse_name,
        sm.sm_ship_mode_id,
        t.t_hour,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        (
            SELECT COUNT(*)
            FROM reason r_sub
            WHERE r_sub.r_reason_desc = 'Damaged'
        ) AS total_damaged_reason_count
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_time_sk = t.t_time_sk
    WHERE i.i_brand = 'Brand#12'
      AND i.i_color = 'Red'
      AND w.w_state = 'CA'
      AND cd_refund.cd_gender = 'F'
      AND t.t_hour = 14
      AND sm.sm_contract = '5FKNB0j8aaqTB'
      AND cr.cr_refunded_customer_sk IN (
          SELECT c_customer_sk
          FROM customer
          WHERE c_preferred_cust_flag = 'Y'
      )
    GROUP BY
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        w.w_warehouse_name,
        sm.sm_ship_mode_id,
        t.t_hour
)
LIMIT 100
