WITH high_qty_items AS (
    SELECT DISTINCT cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
)
SELECT
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_state, '-', s.s_city) AS state_city,
    p.p_promo_name,
    REGEXP_EXTRACT(p.p_promo_name, '(\\w+)', 1) AS promo_first_word,
    SUBSTRING(s.s_store_name, 1, 3) AS store_name_prefix,
    hd.hd_buy_potential,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE ss.ss_item_sk IN (SELECT cs_item_sk FROM high_qty_items)
  AND REGEXP_LIKE(p.p_promo_name, '^.*Discount.*$')
  AND s.s_city LIKE 'A%'
  AND hd.hd_buy_potential LIKE 'high%'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    REGEXP_EXTRACT(p.p_promo_name, '(\\w+)', 1),
    SUBSTRING(s.s_store_name, 1, 3),
    hd.hd_buy_potential
ORDER BY total_profit DESC
LIMIT 100
