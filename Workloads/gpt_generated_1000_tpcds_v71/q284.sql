WITH
    -- Base date dimension for store sales and common joins
    d_sales AS (
        SELECT * FROM date_dim
    ),
    -- Additional date dimensions for returns and web site (joined via the same key)
    d_cr AS (
        SELECT * FROM date_dim
    ),
    d_wr AS (
        SELECT * FROM date_dim
    )
SELECT
    d_sales.d_year,
    i.i_category,
    cc.cc_division_name,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS catalog_profit_status
FROM store_sales ss
JOIN d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk

-- Catalog sales linked through the same date key
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
JOIN customer_address ca_cs_bill ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk

-- Catalog returns tied to the catalog sale
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk

-- Web returns linked through the same item dimension
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r3 ON wr.wr_reason_sk = r3.r_reason_sk

-- Web site information linked via its open date
JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
GROUP BY
    d_sales.d_year,
    i.i_category,
    cc.cc_division_name
ORDER BY
    total_store_sales DESC
LIMIT 100
