SELECT
    s.s_store_name,
    i.i_category,
    CONCAT(i.i_product_name, ' ', i.i_brand) AS product_desc,
    REGEXP_EXTRACT(i.i_product_name, '([A-Z]{2}[0-9]{3})') AS extracted_code,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS transaction_count
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2002
  AND REGEXP_LIKE(i.i_product_name, '[A-Z]{2}[0-9]{3}')
  AND p.p_promo_name LIKE '%Holiday%'
  AND ss.ss_net_profit > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN date_dim d2
            ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2002
    )
GROUP BY
    s.s_store_name,
    i.i_category,
    i.i_product_name,
    i.i_brand,
    CONCAT(i.i_product_name, ' ', i.i_brand),
    REGEXP_EXTRACT(i.i_product_name, '([A-Z]{2}[0-9]{3})')
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
