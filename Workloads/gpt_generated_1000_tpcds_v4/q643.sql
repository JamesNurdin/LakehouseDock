WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        p.p_promo_id,
        p.p_promo_name,
        i.i_brand,
        i.i_product_name,
        d.d_year,
        d.d_month_seq,
        ca.ca_suite_number,
        ca.ca_city
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND ca.ca_suite_number LIKE 'Suite %'
      AND CAST(regexp_extract(ca.ca_suite_number, '\\d+') AS integer) > 200
)
SELECT
    p_promo_id,
    p_promo_name,
    concat(i_brand, ' ', i_product_name) AS full_product_name,
    d_year,
    d_month_seq,
    sum(ss_net_profit) AS total_net_profit,
    sum(ss_quantity) AS total_quantity,
    count(*) AS sales_transactions,
    substring(ca_city, 1, 3) AS city_prefix
FROM filtered_sales
GROUP BY
    p_promo_id,
    p_promo_name,
    i_brand,
    i_product_name,
    d_year,
    d_month_seq,
    substring(ca_city, 1, 3)
HAVING sum(ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
