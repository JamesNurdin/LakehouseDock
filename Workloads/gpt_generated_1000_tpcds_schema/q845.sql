WITH
  full_join AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
      CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_category
    FROM store_sales ss
    FULL OUTER JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_quantity > 0
  ),
  set_a AS (
    SELECT ss.ss_store_sk AS store_sk,
           ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
  ),
  set_b AS (
    SELECT ss.ss_store_sk AS store_sk,
           ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_shift = 'morning'
  ),
  set_c AS (
    SELECT ss.ss_store_sk AS store_sk,
           ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
  ),
  intersect_set AS (
    SELECT store_sk, item_sk FROM set_a
    INTERSECT
    SELECT store_sk, item_sk FROM set_b
  ),
  final_set AS (
    SELECT store_sk, item_sk FROM intersect_set
    EXCEPT
    SELECT store_sk, item_sk FROM set_c
  )
SELECT
  fj.ss_store_sk AS store_sk,
  fj.ss_item_sk AS item_sk,
  fj.promo_category,
  SUM(fj.ss_quantity) AS total_quantity_sold,
  COUNT(DISTINCT fj.promo_name) AS distinct_promo_count,
  CASE
    WHEN SUM(fj.ss_quantity) >= 100 THEN 'High Volume'
    WHEN SUM(fj.ss_quantity) >= 50 THEN 'Medium Volume'
    ELSE 'Low Volume'
  END AS volume_category
FROM full_join fj
JOIN final_set fs
  ON fj.ss_store_sk = fs.store_sk
 AND fj.ss_item_sk = fs.item_sk
GROUP BY
  fj.ss_store_sk,
  fj.ss_item_sk,
  fj.promo_category
HAVING
  SUM(fj.ss_quantity) > 10
ORDER BY total_quantity_sold DESC
LIMIT 100
