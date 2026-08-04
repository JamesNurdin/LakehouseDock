WITH sales_join AS (
  SELECT DISTINCT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    cs.cs_sold_time_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk,
    cp.cp_catalog_page_id,
    cp.cp_description,
    cp.cp_catalog_number,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    td.t_shift
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE regexp_like(cp.cp_description, '[0-9]{3,}')
    AND cp.cp_description LIKE '%sale%'
),
exploded AS (
  SELECT
    sj.cp_catalog_page_id AS cp_id,
    sj.p_promo_name AS promo_name,
    sj.sm_ship_mode_id AS ship_mode_id,
    sj.t_shift,
    sj.cs_order_number AS order_number,
    sj.cs_ext_sales_price,
    sj.cs_quantity,
    word
  FROM sales_join sj
  CROSS JOIN UNNEST(split(sj.cp_description, ' ')) AS t(word)
)
SELECT
  cp_id,
  promo_name,
  ship_mode_id,
  t_shift,
  COUNT(DISTINCT order_number) AS distinct_orders,
  SUM(cs_ext_sales_price) AS total_sales,
  SUM(cs_quantity) AS total_quantity,
  COUNT(DISTINCT word) FILTER (WHERE regexp_like(word, '^[A-Za-z]+$')) AS distinct_words_in_desc
FROM exploded
WHERE regexp_like(word, '^[A-Za-z]+$')
GROUP BY cp_id, promo_name, ship_mode_id, t_shift
ORDER BY total_sales DESC
LIMIT 100
