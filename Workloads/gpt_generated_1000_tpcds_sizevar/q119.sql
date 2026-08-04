WITH filtered_sales AS (
    SELECT
        cs_bill_customer_sk,
        cs_ext_sales_price,
        cs_quantity,
        cs_ext_list_price,
        cs_bill_addr_sk
    FROM catalog_sales
    WHERE cs_quantity > 30
      AND cs_ext_list_price > 1000
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    REGEXP_EXTRACT(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
    SUM(s.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_visited,
    MAX(s.cs_quantity) AS max_quantity
FROM filtered_sales s
JOIN customer c
    ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON s.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE REGEXP_LIKE(c.c_email_address, '^\\w+\\d+@.*\\.com$')
  AND ca.ca_city LIKE 'Mar%'
  AND REGEXP_LIKE(ca.ca_suite_number, '^Suite [A-Z]')
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
          AND cs2.cs_ext_sales_price > 5000
      )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    c.c_email_address
ORDER BY total_sales DESC
LIMIT 100
