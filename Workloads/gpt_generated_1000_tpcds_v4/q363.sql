WITH sales_ship AS (
    SELECT
        ca.ca_state,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_sold_date_sk,
        ca.ca_address_id
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        regexp_like(ca.ca_address_id, '^A{5,}.*$')
        AND ca.ca_state LIKE 'C%'
        AND sm.sm_type LIKE '%AIR%'
)
SELECT
    s.ca_state,
    s.cs_sold_date_sk,
    COUNT(*) AS orders_count,
    SUM(s.cs_quantity) AS total_quantity,
    SUM(s.cs_net_profit) AS total_net_profit,
    AVG(s.cs_ext_sales_price) AS avg_ext_sales_price,
    MIN(regexp_extract(s.ca_address_id, '(A{5,})(.*)', 2)) AS address_suffix_sample,
    (
        SELECT COUNT(*)
        FROM web_page wp
        WHERE wp.wp_creation_date_sk = s.cs_sold_date_sk
          AND regexp_like(wp.wp_url, '^https?://.*promo.*$')
    ) AS promo_page_count
FROM sales_ship s
GROUP BY s.ca_state, s.cs_sold_date_sk
HAVING SUM(s.cs_net_profit) > (
    SELECT AVG(cs_net_profit) FROM catalog_sales
)
ORDER BY total_net_profit DESC
LIMIT 5
