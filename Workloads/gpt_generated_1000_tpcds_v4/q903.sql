WITH sales_enriched AS (
    SELECT
        d.d_year,
        ca.ca_county,
        ca.ca_city,
        p.p_promo_name,
        ss.ss_net_profit,
        substr(ca.ca_city, 1, 3) AS city_prefix,
        regexp_extract(ca.ca_city, '(\\w+)', 1) AS city_first_word
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^(San|New)')
      AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    d_year,
    ca_county,
    COUNT(DISTINCT p_promo_name) AS distinct_promos,
    SUM(ss_net_profit) AS total_net_profit,
    MAX(city_prefix) AS example_city_prefix
FROM sales_enriched
GROUP BY d_year, ca_county
HAVING SUM(ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
