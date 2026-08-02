WITH avg_net_paid AS (
    SELECT AVG(cs_sub.cs_net_paid) AS avg_net
    FROM catalog_sales cs_sub
)
SELECT
    i.i_brand,
    i.i_category,
    CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
    REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{3}[0-9]{2})', 1) AS item_code_extracted,
    SUBSTRING(i.i_product_name, 1, 5) AS product_prefix,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS order_count,
    AVG(cs.cs_ext_tax) AS avg_tax,
    MAX(cs.cs_sales_price) AS max_sales_price,
    MIN(cs.cs_sold_date_sk) AS earliest_sold_date_sk
FROM
    catalog_sales cs
JOIN
    item i
      ON cs.cs_item_sk = i.i_item_sk
JOIN
    customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN
    time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
JOIN
    promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
WHERE
    REGEXP_LIKE(i.i_item_desc, '\\b[A-Z]{3}[0-9]{2}\\b')
    AND ca.ca_zip LIKE '9%'
    AND t.t_shift = 'first'
    AND t.t_minute BETWEEN 10 AND 20
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_channel_tv = 'Y'
    )
GROUP BY
    i.i_brand,
    i.i_category,
    CONCAT(i.i_brand, '-', i.i_category),
    REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{3}[0-9]{2})', 1),
    SUBSTRING(i.i_product_name, 1, 5)
HAVING
    SUM(cs.cs_net_paid) > (SELECT avg_net FROM avg_net_paid)
ORDER BY
    total_net_paid DESC
LIMIT 100
