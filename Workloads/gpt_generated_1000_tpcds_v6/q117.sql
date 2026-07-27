WITH sales_enriched AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_item_sk,
        d.d_year,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        ca.ca_city,
        ca.ca_state,
        CASE WHEN cs.cs_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END AS discount_level,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word,
        concat(i.i_brand, ' ', i.i_product_name) AS full_product,
        substring(ca.ca_city, 1, 3) AS city_prefix
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND regexp_like(i.i_product_name, '^.*[0-9]{3}.*$')
      AND ca.ca_city LIKE 'A%'
)
SELECT
    d_year,
    i_category,
    discount_level,
    COUNT(DISTINCT cs_order_number) AS orders,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    MIN(first_word) AS sample_first_word,
    MAX(full_product) AS sample_full_product,
    MAX(city_prefix) AS sample_city_prefix
FROM sales_enriched
GROUP BY d_year, i_category, discount_level
ORDER BY total_sales DESC
LIMIT 100
