WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        p.p_promo_name,
        ca.ca_suite_number,
        ca.ca_city,
        hd.hd_vehicle_count,
        regexp_extract(p.p_promo_name, '\\d+') AS promo_code
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(p.p_promo_name, '\\d{3}')
      AND ca.ca_suite_number LIKE '%0'
      AND ca.ca_city LIKE 'S%'
      AND hd.hd_vehicle_count >= 2
)
SELECT
    p_promo_name,
    promo_code,
    ca_city,
    COUNT(*) AS sales_count,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(ss_quantity) AS avg_quantity
FROM filtered_sales
GROUP BY p_promo_name, promo_code, ca_city
ORDER BY total_net_profit DESC
LIMIT 100
