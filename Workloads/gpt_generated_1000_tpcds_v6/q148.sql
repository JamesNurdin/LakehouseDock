WITH
    -- Alias date_dim twice for different surrogate keys
    d_sales AS (
        SELECT * FROM tpcds.date_dim
    ),
    d_return AS (
        SELECT * FROM tpcds.date_dim
    )
SELECT DISTINCT
    d_sales.d_year,
    d_sales.d_month_seq,
    i.i_category,
    i.i_brand,
    c.c_first_name,
    c.c_last_name,
    CASE WHEN ws.ws_ext_ship_cost > 100 THEN 'HIGH' ELSE 'LOW' END AS ship_cost_category,
    SUM(ss.ss_net_paid)                       AS total_net_paid,
    SUM(ws.ws_net_profit)                     AS total_web_profit,
    COUNT(DISTINCT ws.ws_order_number)        AS distinct_orders
FROM tpcds.store_sales ss
JOIN d_sales      ON ss.ss_sold_date_sk   = d_sales.d_date_sk          -- store_sales → date_dim
JOIN tpcds.item   i                    ON ss.ss_item_sk        = i.i_item_sk                -- store_sales → item
JOIN tpcds.customer c                 ON ss.ss_customer_sk    = c.c_customer_sk            -- store_sales → customer
JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk       = hd.hd_demo_sk              -- store_sales → household_demographics
JOIN tpcds.customer_address ca       ON ss.ss_addr_sk        = ca.ca_address_sk           -- store_sales → customer_address
JOIN tpcds.store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number        -- store_returns ↔ store_sales (ticket)
                                       AND sr.sr_item_sk       = ss.ss_item_sk                -- store_returns ↔ store_sales (item)
JOIN d_return      ON sr.sr_returned_date_sk = d_return.d_date_sk         -- store_returns → date_dim (return date)
JOIN tpcds.web_sales ws            ON ws.ws_item_sk        = i.i_item_sk                -- web_sales → item (same item as store_sales)
                                       AND ws.ws_bill_customer_sk = c.c_customer_sk        -- web_sales → customer (same customer)
JOIN tpcds.web_page wp           ON ws.ws_web_page_sk    = wp.wp_web_page_sk           -- web_sales → web_page
JOIN tpcds.ship_mode sm          ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk          -- web_sales → ship_mode
JOIN tpcds.warehouse w           ON ws.ws_warehouse_sk   = w.w_warehouse_sk            -- web_sales → warehouse
JOIN tpcds.call_center cc        ON cc.cc_closed_date_sk = d_sales.d_date_sk          -- call_center → date_dim (closed date)
JOIN tpcds.catalog_page cp        ON cp.cp_start_date_sk = d_sales.d_date_sk          -- catalog_page → date_dim (start date)
WHERE EXISTS (
    SELECT 1
    FROM tpcds.catalog_page cp2
    WHERE cp2.cp_department = 'Books'
      AND cp2.cp_start_date_sk = d_sales.d_date_sk
)
  AND d_sales.d_holiday = 'N'
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    i.i_category,
    i.i_brand,
    c.c_first_name,
    c.c_last_name,
    CASE WHEN ws.ws_ext_ship_cost > 100 THEN 'HIGH' ELSE 'LOW' END
ORDER BY total_net_paid DESC
LIMIT 100
