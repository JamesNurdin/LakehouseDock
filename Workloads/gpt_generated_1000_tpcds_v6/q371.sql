WITH bill_sales AS (
    SELECT
        i.i_category,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt,
        MAX(regexp_extract(i.i_item_desc, '(\\w+)', 1)) AS sample_word,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_paid) DESC) AS category_rank
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_class, '^furn')
      AND ca.ca_city LIKE 'San%'
    GROUP BY i.i_category, ca.ca_city, ca.ca_state, ca.ca_zip
    HAVING SUM(cs.cs_net_paid) > 10000
),
ship_sales AS (
    SELECT
        i.i_category,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt,
        MAX(regexp_extract(i.i_item_desc, '(\\w+)', 1)) AS sample_word,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_paid) DESC) AS category_rank
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE i.i_size LIKE 'large%'
      AND regexp_like(ca.ca_street_type, '^R')
      AND ca.ca_zip LIKE '9%'
    GROUP BY i.i_category, ca.ca_city, ca.ca_state, ca.ca_zip
    HAVING SUM(cs.cs_net_paid) > 5000
)
SELECT
    i_category,
    ca_city,
    ca_state,
    CONCAT(ca_city, ', ', ca_state) AS city_state,
    SUBSTR(ca_zip, 1, 3) AS zip_prefix,
    total_sales,
    sales_cnt,
    sample_word,
    category_rank
FROM bill_sales
UNION ALL
SELECT
    i_category,
    ca_city,
    ca_state,
    CONCAT(ca_city, ', ', ca_state) AS city_state,
    SUBSTR(ca_zip, 1, 3) AS zip_prefix,
    total_sales,
    sales_cnt,
    sample_word,
    category_rank
FROM ship_sales
ORDER BY i_category, total_sales DESC
LIMIT 100
