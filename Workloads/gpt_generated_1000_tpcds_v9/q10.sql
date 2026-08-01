SELECT
    cp.cp_catalog_page_number,
    ca.ca_state,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_bill_customers,
    MIN(cs.cs_ext_tax) AS min_tax,
    MAX(cs.cs_ext_tax) AS max_tax
FROM catalog_sales cs
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE ca.ca_gmt_offset = -5.00
    AND ca.ca_county = 'Oldham County'
    AND cp.cp_catalog_page_number = 15
    AND cs.cs_ship_mode_sk = 5
    AND cs.cs_ext_tax > (
        SELECT AVG(cs2.cs_ext_tax)
        FROM catalog_sales cs2
    )
    AND ca.ca_state IN (
        SELECT ca2.ca_state
        FROM customer_address ca2
        WHERE ca2.ca_gmt_offset = -5.00
        UNION
        SELECT ca3.ca_state
        FROM customer_address ca3
        WHERE ca3.ca_state = 'CA'
    )
GROUP BY cp.cp_catalog_page_number, ca.ca_state
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
