/* Goal: Analyze total revenue and loss across catalog sales, catalog returns, store returns, and web sales, broken down by year, catalog department and customer credit rating, with subtotals using GROUPING SETS. */
WITH
    -- Alias date and time dimensions for different roles
    d_sales        AS (SELECT * FROM date_dim),
    d_cr_return    AS (SELECT * FROM date_dim),
    d_sr_return    AS (SELECT * FROM date_dim),
    d_wp_creation  AS (SELECT * FROM date_dim),
    d_wp_access    AS (SELECT * FROM date_dim),
    t_sales        AS (SELECT * FROM time_dim),
    t_cr_return    AS (SELECT * FROM time_dim),
    t_sr_return    AS (SELECT * FROM time_dim)
SELECT
    d_sales.d_year,
    cp.cp_department,
    cd_bill.cd_credit_rating,
    SUM(cs.cs_net_paid)                                 AS total_catalog_sales,
    SUM(cr.cr_net_loss)                                 AS total_catalog_returns_loss,
    SUM(sr.sr_net_loss)                                 AS total_store_returns_loss,
    SUM(ws.ws_net_paid)                                 AS total_web_sales,
    SUM(CASE WHEN cd_bill.cd_credit_rating = 'Good' THEN cs.cs_net_paid ELSE 0 END) AS good_credit_sales,
    COUNT(DISTINCT c_bill.c_customer_id)                AS distinct_customers
FROM
    catalog_sales cs
    JOIN d_sales d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN t_sales t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    -- Catalog returns linked to catalog sales
    JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
                           AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN d_cr_return d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    JOIN t_cr_return t_cr_return ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
    -- Store returns
    JOIN store_returns sr ON sr.sr_customer_sk = c_bill.c_customer_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN d_sr_return d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
    JOIN t_sr_return t_sr_return ON sr.sr_return_time_sk = t_sr_return.t_time_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    -- Web sales
    JOIN web_sales ws ON ws.ws_item_sk = cs.cs_item_sk
                      AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN d_wp_creation d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN d_wp_access d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
GROUP BY
    GROUPING SETS (
        (d_sales.d_year, cp.cp_department, cd_bill.cd_credit_rating),
        (d_sales.d_year, cp.cp_department),
        (d_sales.d_year),
        ()
    )
ORDER BY
    d_sales.d_year DESC,
    cp.cp_department,
    cd_bill.cd_credit_rating
LIMIT 100
