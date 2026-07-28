WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM tpcds.customer AS c
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND c.c_first_name LIKE 'J%'
)
SELECT
    i.i_category,
    i.i_brand,
    concat(i.i_brand, ' - ', i.i_category) AS brand_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    MIN(f.email_domain) AS example_domain
FROM filtered_customers AS f
JOIN tpcds.store_sales AS ss
    ON ss.ss_customer_sk = f.c_customer_sk
JOIN tpcds.item AS i
    ON ss.ss_item_sk = i.i_item_sk
WHERE regexp_like(i.i_item_desc, '.*(Premium|Deluxe).*')
  AND i.i_product_name LIKE '%Ultra%'
GROUP BY
    i.i_category,
    i.i_brand,
    concat(i.i_brand, ' - ', i.i_category)
ORDER BY total_sales DESC
LIMIT 100
