WITH catalog_agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    (SELECT COUNT(*) FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y') AS promo_active_cnt
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE sm.sm_contract = 'Ek'
    AND hd.hd_vehicle_count > 2
    AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y')
  GROUP BY i.i_item_id, i.i_product_name, i.i_item_sk
),
web_agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    SUM(wr.wr_return_amt) AS total_return_amount,
    (SELECT COUNT(*) FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y') AS promo_active_cnt
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_dep_count <= 4
    AND wr.wr_account_credit > 100
    AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y')
  GROUP BY i.i_item_id, i.i_product_name, i.i_item_sk
)
SELECT
  item_id,
  product_name,
  total_return_amount,
  promo_active_cnt,
  SUM(total_return_amount) OVER (
    PARTITION BY item_id
    ORDER BY total_return_amount DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total
FROM (
  SELECT i_item_id AS item_id, i_product_name AS product_name, total_return_amount, promo_active_cnt
  FROM catalog_agg
  UNION
  SELECT i_item_id, i_product_name, total_return_amount, promo_active_cnt
  FROM web_agg
) u
ORDER BY total_return_amount DESC
OFFSET 0
LIMIT 100
