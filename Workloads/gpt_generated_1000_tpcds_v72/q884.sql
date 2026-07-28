WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        ws.ws_ship_date_sk AS ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_mode_sk AS ws_ship_mode_sk,
        ws.ws_warehouse_sk AS ws_warehouse_sk,
        ws.ws_promo_sk AS ws_promo_sk,
        ws.ws_order_number,
        ws.ws_ext_tax,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        wp.wp_web_page_sk,
        wp.wp_creation_date_sk,
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        inv.inv_date_sk AS inv_date_sk,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN web_sales ws ON ws.ws_item_sk = cs.cs_item_sk
        AND ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
        AND ws.ws_bill_addr_sk = cs.cs_bill_addr_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = cs.cs_item_sk
    JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
        AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE cs.cs_net_paid_inc_tax > 0
)
SELECT
    d_sold.d_year AS sales_year,
    w.w_state AS warehouse_state,
    i.i_category AS item_category,
    SUM(b.cs_net_paid_inc_tax) AS total_catalog_sales,
    SUM(b.ws_ext_tax) AS total_web_tax,
    COUNT(DISTINCT b.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(b.cs_net_profit) > 1000000 THEN 'High'
        WHEN SUM(b.cs_net_profit) > 500000  THEN 'Medium'
        ELSE 'Low'
    END AS profit_bucket,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(b.cs_net_paid_inc_tax) DESC) AS sales_rank
FROM base b
JOIN date_dim d_sold ON b.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON b.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer cust_bill ON b.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_address addr_bill ON b.cs_bill_addr_sk = addr_bill.ca_address_sk
JOIN customer cust_ship ON b.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_address addr_ship ON b.cs_ship_addr_sk = addr_ship.ca_address_sk
JOIN ship_mode sm ON b.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON b.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON b.cs_item_sk = i.i_item_sk
JOIN promotion p ON b.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm_ws ON b.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws ON b.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws ON b.ws_promo_sk = p_ws.p_promo_sk
JOIN date_dim d_ws_ship ON b.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN date_dim d_wp_creation ON b.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wr_returned ON b.wr_returned_date_sk = d_wr_returned.d_date_sk
GROUP BY
    d_sold.d_year,
    w.w_state,
    i.i_category
ORDER BY total_catalog_sales DESC
LIMIT 100
