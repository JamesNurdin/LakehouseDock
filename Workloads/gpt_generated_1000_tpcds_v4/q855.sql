WITH sales_promo AS (
    SELECT
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_profit AS net_profit,
        p.p_promo_name AS promo_name,
        ca.ca_county,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND ca.ca_county LIKE '%County'
)
SELECT
    regexp_extract(promo_name, '(\\d+)', 1) AS promo_number,
    ca_county,
    concat(ca_city, ', ', ca_state) AS city_state,
    substring(ca_zip, 1, 5) AS zip5,
    sum(ext_sales_price) AS total_sales,
    avg(net_profit) AS avg_profit
FROM sales_promo
GROUP BY
    regexp_extract(promo_name, '(\\d+)', 1),
    ca_county,
    concat(ca_city, ', ', ca_state),
    substring(ca_zip, 1, 5)
ORDER BY total_sales DESC
LIMIT 20
