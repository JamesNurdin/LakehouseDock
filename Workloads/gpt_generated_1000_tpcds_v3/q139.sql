WITH pattern_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        ca.ca_city,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        i.i_manufact
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_manufact, 'able$')
      AND ca.ca_city LIKE '%ville'
),

cally_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        ca.ca_city,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        i.i_manufact
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_manufact, '^cally')
      AND ca.ca_state = 'TX'
)
SELECT
    u.i_category,
    u.ca_city,
    COUNT(DISTINCT u.i_item_sk) AS distinct_items_sold,
    SUM(u.ss_net_profit) AS total_net_profit,
    AVG(u.ss_ext_discount_amt) AS avg_discount,
    CONCAT('Manuf: ', regexp_extract(max(u.i_manufact), '(.*)able', 1)) AS manufact_prefix,
    (SELECT AVG(ss2.ss_ext_discount_amt) FROM store_sales ss2) AS overall_avg_discount
FROM (
    SELECT * FROM pattern_sales
    UNION ALL
    SELECT * FROM cally_sales
) u
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    JOIN store_sales ss3 ON p.p_promo_sk = ss3.ss_promo_sk
    WHERE ss3.ss_item_sk = u.i_item_sk
      AND p.p_discount_active = 'Y'
)
GROUP BY u.i_category, u.ca_city
HAVING SUM(u.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
