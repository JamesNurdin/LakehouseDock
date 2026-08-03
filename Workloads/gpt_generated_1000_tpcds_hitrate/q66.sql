WITH sales_agg AS (
    SELECT
        ca.ca_city AS ca_city,
        c.c_birth_country AS c_birth_country,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High'
            ELSE 'Low'
        END AS sales_category,
        regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS item_prefix
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND regexp_like(ca.ca_city, '^New')
      AND i.i_color LIKE '%purple%'
      AND regexp_extract(i.i_item_desc, '\\d+', 0) <> ''
    GROUP BY ca.ca_city, c.c_birth_country, regexp_extract(i.i_item_desc, '^([^ ]+)', 1)
)

SELECT ca_city,
       c_birth_country,
       num_customers,
       total_sales,
       sales_category,
       item_prefix
FROM sales_agg
WHERE sales_category = 'High'

UNION

SELECT ca_city,
       c_birth_country,
       num_customers,
       total_sales,
       sales_category,
       item_prefix
FROM sales_agg
WHERE sales_category = 'Low' AND total_sales > 5000

ORDER BY total_sales DESC
LIMIT 100
