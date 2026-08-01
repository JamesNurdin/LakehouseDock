WITH joined_data AS (
    SELECT
        d_sales.d_year AS d_year,
        d_sales.d_month_seq AS d_month_seq,
        s.s_state AS s_state,
        we.web_name AS web_name,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        ss.ss_ext_sales_price AS store_sales_amount,
        sr.sr_return_amt AS store_return_amount,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        cr.cr_return_amount AS catalog_return_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        inv.inv_quantity_on_hand AS inventory_qty
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    -- store closed date (date_dim instance)
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    -- income band for the household demographic
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- inventory and its warehouse
    JOIN inventory inv
        ON inv.inv_date_sk = d_sales.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    -- catalog sales (joined through shared dimensions)
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
       AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
       AND cs.cs_bill_addr_sk = ca.ca_address_sk
       AND cs.cs_warehouse_sk = w.w_warehouse_sk
    -- catalog returns (matched to catalog sales)
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sales.d_date_sk
       AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
       AND cr.cr_refunded_addr_sk = ca.ca_address_sk
       AND cr.cr_warehouse_sk = w.w_warehouse_sk
       AND cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    -- store returns (matched to store sales)
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sales.d_date_sk
       AND sr.sr_store_sk = s.s_store_sk
       AND sr.sr_hdemo_sk = hd.hd_demo_sk
       AND sr.sr_addr_sk = ca.ca_address_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    -- web site (joined via open date)
    JOIN web_site we
        ON we.web_open_date_sk = d_sales.d_date_sk
    -- web sales (joined through shared dimensions)
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sales.d_date_sk
       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_bill_addr_sk = ca.ca_address_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_web_site_sk = we.web_site_sk
    WHERE d_sales.d_year = 2000
      AND ca.ca_location_type = 'apartment'
      AND cr.cr_returned_time_sk BETWEEN 30000 AND 50000
      AND cs.cs_ext_discount_amt > 1000
      AND inv.inv_quantity_on_hand > 5000
)
SELECT
    d_year,
    d_month_seq,
    s_state,
    web_name,
    ib_lower_bound,
    ib_upper_bound,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(store_return_amount) AS total_store_returns,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    SUM(catalog_return_amount) AS total_catalog_returns,
    SUM(web_sales_amount) AS total_web_sales,
    SUM(inventory_qty) AS total_inventory_qty
FROM joined_data
GROUP BY GROUPING SETS (
    (d_year, d_month_seq, s_state, web_name, ib_lower_bound, ib_upper_bound),
    (d_year, d_month_seq, s_state, web_name),
    (d_year, d_month_seq, s_state),
    (d_year, d_month_seq),
    ()
)
ORDER BY d_year, d_month_seq, s_state, web_name
LIMIT 100
