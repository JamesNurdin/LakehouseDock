WITH filtered_sales AS (
    SELECT
        s.s_store_name            AS store_name,
        s.s_city                  AS store_city,
        p.p_promo_name            AS promo_name,
        regexp_extract(p.p_promo_name, '([A-Z]{3})', 1) AS promo_code,
        i.i_item_desc             AS item_desc,
        ss.ss_net_paid            AS net_paid,
        ca.ca_city                AS customer_city,
        substr(ca.ca_city, 1, 3)  AS city_prefix,
        regexp_extract(i.i_item_desc, '(?i)(shirt)', 1) AS matched_word
    FROM store_sales ss
    JOIN store s          ON ss.ss_store_sk = s.s_store_sk
    JOIN item i          ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p    ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)shirt')
      AND ca.ca_city LIKE 'S%'
)
SELECT
    store_name,
    promo_name,
    promo_code,
    COUNT(*)                       AS transaction_count,
    SUM(net_paid)                  AS total_net_paid,
    SUM(net_paid) / COUNT(*)       AS avg_net_paid,
    MIN(city_prefix)               AS sample_city_prefix
FROM filtered_sales
GROUP BY store_name, promo_name, promo_code
ORDER BY total_net_paid DESC
LIMIT 10
