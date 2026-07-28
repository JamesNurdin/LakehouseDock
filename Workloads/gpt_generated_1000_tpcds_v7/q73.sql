WITH sales_2022 AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_zip,
        ca.ca_zip,
        p.p_promo_name,
        d.d_year
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2022
)
SELECT
    s.s_store_id,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    REGEXP_EXTRACT(ca.ca_zip, '(\\d{5})') AS zip_5,
    COUNT(*) AS transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_sales_price) AS avg_sales_per_tx,
    SUM(CASE WHEN REGEXP_LIKE(p.p_promo_name, '(?i)discount') THEN ss.ss_ext_sales_price ELSE 0 END) AS discount_sales
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2022
  AND REGEXP_LIKE(s.s_city, '^.*ville$')
  AND ca.ca_zip LIKE '9___'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND p2.p_discount_active = 'Y'
          AND p2.p_promo_name LIKE '%Clearance%'
    )
GROUP BY s.s_store_id, s.s_city, s.s_state, ca.ca_zip, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
