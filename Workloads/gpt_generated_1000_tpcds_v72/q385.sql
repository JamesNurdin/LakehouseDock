SELECT
    cp.cp_catalog_page_number,
    ca.ca_state,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    CASE WHEN SUM(sr.sr_return_amt) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_status
FROM
    catalog_page cp
JOIN catalog_sales cs
    ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
   AND ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
WHERE
    cp.cp_catalog_page_number IN (13, 15)
    AND cp.cp_start_date_sk = 2451210
    AND cs.cs_quantity > 5
    AND cs.cs_sales_price BETWEEN 100 AND 500
    AND ca.ca_state = 'TX'
    AND ib.ib_upper_bound >= 50000
    AND sm.sm_type = 'AIR'
    AND sr.sr_return_tax > 1.0
GROUP BY
    cp.cp_catalog_page_number,
    ca.ca_state,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING
    SUM(cs.cs_ext_sales_price) > 10000
    AND COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY
    total_sales DESC
LIMIT 100
