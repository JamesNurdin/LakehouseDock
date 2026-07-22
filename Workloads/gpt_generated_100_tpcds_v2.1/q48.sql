/*
Goal: Analyze combined sales, catalog returns, and store returns performance by warehouse city, product department, customer gender, household buying potential, website, and income band, focusing on customers born in 1961 and inventory on a specific date.
*/
SELECT
    w.w_city AS warehouse_city,
    cp.cp_department AS department,
    cd.cd_gender AS gender,
    hd.hd_buy_potential AS buy_potential,
    we.web_name AS website_name,
    ib.ib_income_band_sk AS income_band_id,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    AVG(ws.ws_quantity) AS avg_web_quantity,
    MIN(i.inv_quantity_on_hand) AS min_quantity_on_hand,
    MAX(i.inv_quantity_on_hand) AS max_quantity_on_hand
FROM
    customer c
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = sr.sr_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
    JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
WHERE
    c.c_birth_year = 1961
    AND w.w_city = 'Pleasant Hill'
    AND i.inv_date_sk = 2450941
GROUP BY
    w.w_city,
    cp.cp_department,
    cd.cd_gender,
    hd.hd_buy_potential,
    we.web_name,
    ib.ib_income_band_sk
ORDER BY
    total_web_sales DESC
LIMIT 100
