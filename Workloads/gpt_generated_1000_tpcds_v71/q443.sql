WITH sales AS (
    SELECT
        ss.ss_net_profit,
        i.i_category,
        ca.ca_state,
        p.p_promo_name,
        ss.ss_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '\\d{2,}') -- description contains at least two consecutive digits
      AND (p.p_promo_name IS NULL OR p.p_promo_name LIKE '%SALE%')
)
SELECT
    CASE WHEN GROUPING(i_category) = 1 THEN 'All Categories' ELSE i_category END AS category,
    CASE WHEN GROUPING(ca_state) = 1 THEN 'All States' ELSE ca_state END AS state,
    COUNT(DISTINCT p_promo_name) AS distinct_promos,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_net_profit) AS avg_profit,
    SUM(ss_quantity) AS total_quantity
FROM sales
GROUP BY ROLLUP (i_category, ca_state)
HAVING SUM(ss_net_profit) > 10000
ORDER BY category ASC, state ASC, total_profit DESC
LIMIT 100
