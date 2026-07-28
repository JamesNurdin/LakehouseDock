WITH filtered_sales AS (
    SELECT
        cs.cs_net_profit,
        i.i_product_name,
        i.i_brand,
        c.c_email_address,
        d.d_year
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2020
      AND i.i_product_name LIKE '%COFFEE%'
      AND regexp_like(i.i_product_name, '^[A-Z]{2}[0-9]{3}')
      AND regexp_like(c.c_email_address, '@example\\.com$')
)
SELECT
    regexp_extract(i_product_name, '([A-Z]{2}[0-9]{3})', 1) AS product_code,
    i_brand AS brand,
    regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain,
    sum(cs_net_profit) AS total_net_profit
FROM filtered_sales
GROUP BY
    regexp_extract(i_product_name, '([A-Z]{2}[0-9]{3})', 1),
    i_brand,
    regexp_extract(c_email_address, '@(.+)$', 1)
HAVING sum(cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
