WITH high_estimate_counties AS (
    SELECT DISTINCT ca.ca_county
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 2000
      AND ca.ca_country = 'United States'
)
SELECT
    i.i_item_id,
    i.i_product_name,
    concat(i.i_product_name, ' (', i.i_brand, ')') AS product_label,
    regexp_extract(i.i_product_name, '([A-Z]+)', 1) AS product_alpha_prefix,
    MIN(substring(ca.ca_zip, 1, 3)) AS zip_prefix,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2020
  AND regexp_like(i.i_product_name, '^[A-Z]{3}')
  AND ca.ca_city LIKE 'San%'
  AND ca.ca_county IN (SELECT ca_county FROM high_estimate_counties)
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    regexp_extract(i.i_product_name, '([A-Z]+)', 1)
ORDER BY total_sales DESC
LIMIT 10
