WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        i.i_item_id,
        d_sold.d_year,
        ca_bill.ca_state,
        sm.sm_type,
        wh.w_warehouse_name,
        ws.web_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_quantity) > 5 THEN 'Bulk' ELSE 'Regular' END AS quantity_flag
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = wh.w_warehouse_sk
       AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN date_dim d_page_start
        ON cp.cp_start_date_sk = d_page_start.d_date_sk
    JOIN date_dim d_page_end
        ON cp.cp_end_date_sk = d_page_end.d_date_sk
    JOIN web_site ws
        ON d_sold.d_date_sk = ws.web_open_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_category = 'Sports'
      AND ca_bill.ca_state = 'CA'
      AND sm.sm_type = 'OVERNIGHT'
    GROUP BY
        cp.cp_catalog_page_id,
        i.i_item_id,
        d_sold.d_year,
        ca_bill.ca_state,
        sm.sm_type,
        wh.w_warehouse_name,
        ws.web_name
)
SELECT
    cp_catalog_page_id,
    i_item_id,
    total_sales,
    total_returns,
    total_profit,
    quantity_flag,
    CASE WHEN total_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY cp_catalog_page_id ORDER BY total_profit DESC) AS profit_rank
FROM base
ORDER BY profit_rank, total_profit DESC
LIMIT 100
