WITH sales_filtered AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(c.c_first_name, '^A')
      AND regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND i.i_category LIKE '%Electronics%'
)
SELECT
    sf.i_category,
    sf.i_brand,
    COUNT(DISTINCT sf.cs_order_number) AS orders,
    SUM(sf.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT sf.c_customer_sk) AS unique_customers,
    MIN(sf.email_domain) AS sample_domain
FROM sales_filtered sf
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = sf.cs_item_sk
      AND cr.cr_order_number = sf.cs_order_number
)
GROUP BY sf.i_category, sf.i_brand
ORDER BY total_net_paid DESC
LIMIT 100
