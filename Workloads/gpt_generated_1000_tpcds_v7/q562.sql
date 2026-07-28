WITH
    -- Date dimension aliases for each fact table
    d_cs AS (SELECT * FROM date_dim),
    d_ss AS (SELECT * FROM date_dim),
    d_ws AS (SELECT * FROM date_dim),
    d_wr AS (SELECT * FROM date_dim),
    d_wsit AS (SELECT * FROM date_dim)
SELECT
    d_cs.d_year,
    i.i_category,
    sm.sm_carrier,
    SUM(cs.cs_ext_sales_price)      AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price)      AS total_store_sales,
    SUM(ws.ws_ext_sales_price)      AS total_web_sales,
    SUM(wr.wr_return_amt)           AS total_web_returns,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
    COUNT(DISTINCT ws.ws_order_number)  AS web_orders,
    COUNT(DISTINCT wr.wr_order_number)  AS web_return_orders
FROM
    catalog_sales cs
    JOIN d_cs        ON cs.cs_sold_date_sk   = d_cs.d_date_sk
    JOIN item i      ON cs.cs_item_sk        = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    -- Join to store_sales through the shared item
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN d_ss        ON ss.ss_sold_date_sk   = d_ss.d_date_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    -- Join to web_sales through the same item
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN d_ws        ON ws.ws_sold_date_sk   = d_ws.d_date_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN d_wsit      ON wsite.web_open_date_sk = d_wsit.d_date_sk
    -- Join web_returns to the corresponding web_sales order
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN d_wr        ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE
    d_cs.d_year = 2001
    AND sm.sm_carrier = 'FEDEX'
    AND i.i_brand = 'BrandX'
GROUP BY
    ROLLUP (d_cs.d_year, i.i_category, sm.sm_carrier)
ORDER BY
    d_cs.d_year,
    i.i_category,
    sm.sm_carrier
