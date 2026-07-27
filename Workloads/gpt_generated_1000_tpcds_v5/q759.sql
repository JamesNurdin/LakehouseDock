WITH cs_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        d_sold.d_year AS sold_year,
        i.i_category,
        i.i_current_price,
        i.i_item_sk,
        w.w_warehouse_name,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
)
SELECT
    cs_data.sold_year,
    cs_data.i_category,
    cs_data.w_warehouse_name,
    SUM(cs_data.cs_net_paid) AS total_catalog_net_paid,
    COALESCE(SUM(ss_data.ss_net_paid), 0) AS total_store_net_paid,
    COALESCE(SUM(sr_data.sr_net_loss), 0) AS total_store_return_loss,
    COALESCE(SUM(wr_data.wr_net_loss), 0) AS total_web_return_loss,
    MAX(cs_data.i_current_price) AS max_item_price
FROM cs_data
JOIN store_sales ss_data
    ON ss_data.ss_item_sk = cs_data.i_item_sk
   AND ss_data.ss_sold_date_sk = cs_data.cs_sold_date_sk
LEFT JOIN store_returns sr_data
    ON sr_data.sr_ticket_number = ss_data.ss_ticket_number
   AND sr_data.sr_item_sk = ss_data.ss_item_sk
JOIN date_dim d_ss
    ON ss_data.ss_sold_date_sk = d_ss.d_date_sk
LEFT JOIN (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_net_loss,
        wp.wp_web_page_id
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
) wr_data
    ON wr_data.wr_item_sk = cs_data.i_item_sk
   AND wr_data.wr_returned_date_sk = cs_data.cs_sold_date_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr_check
    WHERE sr_check.sr_item_sk = cs_data.i_item_sk
      AND sr_check.sr_returned_date_sk = cs_data.cs_sold_date_sk
)
GROUP BY
    cs_data.sold_year,
    cs_data.i_category,
    cs_data.w_warehouse_name
ORDER BY total_catalog_net_paid DESC
LIMIT 100
