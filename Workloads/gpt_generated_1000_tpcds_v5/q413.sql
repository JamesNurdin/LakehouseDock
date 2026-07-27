/*
Goal: Analyze net revenue, order volume, and price/tax characteristics for recent catalog pages, broken down by call center, department, and billing/shipping states, applying several realistic filters.
*/
WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_order_number,
        cs.cs_ext_tax,
        cs.cs_ext_list_price,
        cs.cs_net_paid
    FROM tpcds.catalog_sales cs
    WHERE
        cs.cs_ext_tax > 20.00
        AND cs.cs_ext_list_price BETWEEN 1000 AND 5000
)
SELECT
    cc.cc_name AS call_center_name,
    cp.cp_department AS department,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    COUNT(DISTINCT fs.cs_order_number) AS order_cnt,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_ext_tax) AS avg_ext_tax,
    MIN(fs.cs_ext_list_price) AS min_list_price,
    MAX(fs.cs_ext_list_price) AS max_list_price
FROM filtered_sales fs
JOIN tpcds.call_center cc
    ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer_address ca_bill
    ON fs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
    ON fs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE
    cp.cp_end_date_sk BETWEEN 2450900 AND 2451100
    AND cp.cp_catalog_page_number IN (1, 13, 21)
    AND ca_bill.ca_gmt_offset = -5.00
    AND ca_ship.ca_street_type = 'Avenue'
GROUP BY
    cc.cc_name,
    cp.cp_department,
    ca_bill.ca_state,
    ca_ship.ca_state
ORDER BY
    total_net_paid DESC
LIMIT 100
