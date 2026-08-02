WITH filtered_sales AS (
    SELECT
        d.d_year,
        cp.cp_department,
        cd.cd_gender,
        ca.ca_location_type,
        regexp_extract(c.c_email_address, '@(.+)$') AS email_domain,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(cp.cp_description, '(?i)clearance')
      AND ca.ca_location_type LIKE 'condo%'
      AND c.c_email_address LIKE '%@example.com'
)
SELECT
    d_year,
    cp_department,
    cd_gender,
    ca_location_type,
    email_domain,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS order_count
FROM filtered_sales
GROUP BY CUBE (d_year, cp_department, cd_gender, ca_location_type, email_domain)
ORDER BY total_net_paid DESC
LIMIT 100
