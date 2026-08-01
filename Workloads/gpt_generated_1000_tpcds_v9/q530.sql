WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cp.cp_description,
        c.c_customer_sk,
        c.c_email_address,
        d.d_year
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND regexp_like(cp.cp_description, '(?i)store')
      AND c.c_email_address LIKE '%@example.com'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
      )
)
SELECT
    cp_catalog_page_id,
    cp_catalog_page_number,
    substring(cp_description, 1, 30) AS short_desc,
    regexp_extract(cp_description, '[A-Za-z]+', 1) AS first_word,
    count(cs_order_number) AS num_orders,
    sum(cs_net_paid) AS total_net_paid
FROM filtered_sales
GROUP BY
    cp_catalog_page_id,
    cp_catalog_page_number,
    substring(cp_description, 1, 30),
    regexp_extract(cp_description, '[A-Za-z]+', 1)
HAVING sum(cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
