WITH filtered_sales AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cp.cp_department,
        cp.cp_catalog_page_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_county
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_county, '^.*County$')
      AND ca.ca_state = 'CA'
      AND cp.cp_department LIKE 'D%'
)
SELECT
    fs.cp_department,
    COUNT(DISTINCT fs.cs_bill_customer_sk) AS unique_customers,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    REGEXP_EXTRACT(fs.cp_catalog_page_id, '[A-Z]+([0-9]+)', 1) AS extracted_page_number,
    CONCAT(SUBSTRING(fs.ca_city, 1, 3), '-', SUBSTRING(fs.ca_state, 1, 2)) AS city_state_code
FROM filtered_sales fs
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = fs.cs_bill_customer_sk
      AND ws.ws_sold_date_sk = fs.cs_sold_date_sk
)
GROUP BY
    fs.cp_department,
    fs.cp_catalog_page_id,
    fs.ca_city,
    fs.ca_state
HAVING AVG(fs.cs_ext_discount_amt) > 5.0
ORDER BY total_sales DESC
LIMIT 100
