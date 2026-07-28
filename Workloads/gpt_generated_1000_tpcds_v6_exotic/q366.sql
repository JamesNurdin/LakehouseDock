WITH promo_agg AS (
  SELECT
    i.i_manager_id AS manager_id,
    i.i_class_id   AS class_id,
    regexp_extract(i.i_product_name, '(\\d{4})') AS prod_code,
    COUNT(*)       AS promo_cnt,
    SUM(p.p_cost)  AS total_cost,
    AVG(p.p_cost)  AS avg_cost
  FROM promotion p
  JOIN item i ON p.p_item_sk = i.i_item_sk
  WHERE regexp_like(i.i_item_desc, '[0-9]{2,}')
    AND p.p_channel_email = 'Y'
    AND i.i_formulation LIKE '%wheat%'
  GROUP BY i.i_manager_id,
           i.i_class_id,
           regexp_extract(i.i_product_name, '(\\d{4})')
),

promo_agg2 AS (
  SELECT
    i.i_manager_id AS manager_id,
    i.i_class_id   AS class_id,
    regexp_extract(i.i_product_name, '(\\d{4})') AS prod_code,
    COUNT(*)       AS promo_cnt,
    SUM(p.p_cost)  AS total_cost,
    AVG(p.p_cost)  AS avg_cost
  FROM promotion p
  JOIN item i ON p.p_item_sk = i.i_item_sk
  WHERE i.i_product_name LIKE concat('%', 'peru', '%')
    AND p.p_discount_active = 'Y'
    AND regexp_like(p.p_promo_name, '^Promo.*202[0-3]$')
  GROUP BY i.i_manager_id,
           i.i_class_id,
           regexp_extract(i.i_product_name, '(\\d{4})')
)

SELECT
  manager_id,
  class_id,
  prod_code,
  promo_cnt,
  total_cost,
  avg_cost
FROM (
  SELECT manager_id, class_id, prod_code, promo_cnt, total_cost, avg_cost FROM promo_agg
  UNION ALL
  SELECT manager_id, class_id, prod_code, promo_cnt, total_cost, avg_cost FROM promo_agg2
) AS combined
ORDER BY total_cost DESC
LIMIT 100
