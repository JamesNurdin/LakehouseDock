WITH promo_avg_cost AS (
    SELECT avg(p_cost) AS avg_cost
    FROM promotion
)
SELECT
    'catalog' AS source,
    sm.sm_ship_mode_id,
    sm.sm_type,
    sum(cs.cs_ext_sales_price) AS total_sales,
    sum(cs.cs_net_profit) AS total_profit
FROM catalog_sales cs
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_sales_price > 20.41
  AND sm.sm_type = 'EXPRESS'
GROUP BY sm.sm_ship_mode_id, sm.sm_type

UNION ALL

SELECT
    'store' AS source,
    p.p_promo_id AS sm_ship_mode_id,
    p.p_promo_name AS sm_type,
    sum(ss.ss_ext_sales_price) AS total_sales,
    sum(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_cost > (SELECT avg_cost FROM promo_avg_cost)
  AND p.p_discount_active = 'Y'
GROUP BY p.p_promo_id, p.p_promo_name

ORDER BY total_sales DESC
LIMIT 100
