WITH filtered_sales AS (
    SELECT
        c.c_customer_id,
        c.c_email_address,
        i.i_brand,
        i.i_item_desc,
        ss.ss_net_paid,
        ss.ss_quantity,
        td.t_hour
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE regexp_like(c.c_email_address, '\\.com$')
      AND p.p_promo_name LIKE '%Discount%'
      AND td.t_hour BETWEEN 12 AND 17
)
SELECT
    i_brand,
    substring(i_item_desc, 1, 10) AS item_desc_prefix,
    concat(i_brand, '_', regexp_extract(c_email_address, '@([^@]+)$', 1)) AS brand_email_key,
    sum(ss_net_paid) AS total_sales,
    avg(ss_quantity) AS avg_quantity,
    count(distinct c_customer_id) AS distinct_customers
FROM filtered_sales
GROUP BY
    i_brand,
    substring(i_item_desc, 1, 10),
    concat(i_brand, '_', regexp_extract(c_email_address, '@([^@]+)$', 1))
ORDER BY total_sales DESC
LIMIT 100
