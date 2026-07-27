WITH base_cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_net_paid
    FROM catalog_sales cs
), base_cr AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_net_loss
    FROM catalog_returns cr
), base_sr AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_net_loss,
        sr.sr_ticket_number
    FROM store_returns sr
), base_wr AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_web_page_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_order_number,
        wr.wr_net_loss
    FROM web_returns wr
), base_inv AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
)
SELECT
    s.s_store_name,
    d_sold.d_year AS sales_year,
    i.i_category,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_returns,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_returns
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk

-- catalog returns
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_cr_ret ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN time_dim t_cr_ret ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN customer cust_refund ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
JOIN customer cust_returning ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk

-- store returns
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer cust_sr ON sr.sr_customer_sk = cust_sr.c_customer_sk

-- inventory
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk

-- web returns
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer cust_wr_ref ON wr.wr_refunded_customer_sk = cust_wr_ref.c_customer_sk
JOIN customer cust_wr_ret ON wr.wr_returning_customer_sk = cust_wr_ret.c_customer_sk
JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer cust_wp ON wp.wp_customer_sk = cust_wp.c_customer_sk

WHERE d_sold.d_year = 2001
  AND i.i_category = 'Sports'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = cust_bill.c_customer_sk
          AND cs2.cs_sold_date_sk = d_sold.d_date_sk
          AND cs2.cs_net_paid > 1000
    )
GROUP BY s.s_store_name, d_sold.d_year, i.i_category
ORDER BY total_catalog_profit DESC
LIMIT 100
