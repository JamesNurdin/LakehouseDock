WITH filtered_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_department,
        regexp_extract(cp_description, '^([A-Za-z]+)', 1) AS first_word_desc
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)sale')
)
SELECT
    cp.cp_department,
    cp.first_word_desc,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_count
FROM catalog_sales cs
JOIN filtered_pages cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2000
  AND ca.ca_city LIKE 'San%'
GROUP BY cp.cp_department, cp.first_word_desc
ORDER BY total_sales DESC
LIMIT 100
