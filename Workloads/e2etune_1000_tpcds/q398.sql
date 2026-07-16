WITH filtered AS (
  SELECT
    cr.cr_item_sk,
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_return_tax,
    cr.cr_store_credit,
    cr.cr_returned_date_sk,
    i.i_category,
    i.i_brand,
    sm.sm_type,
    sm.sm_carrier
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cr.cr_store_credit > 50
    AND cr.cr_item_sk IN (202837, 256550, 239066, 19112, 262387)
    AND i.i_category IS NOT NULL
),
aggregated AS (
  SELECT
    i_category,
    sm_type,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_tax) AS avg_return_tax,
    ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY SUM(cr_net_loss) DESC) AS rn
  FROM filtered
  GROUP BY i_category, sm_type
  HAVING SUM(cr_return_amount) > 1000
)
SELECT
  i_category,
  sm_type,
  return_cnt,
  total_return_amount,
  total_net_loss,
  avg_return_tax
FROM aggregated
WHERE rn <= 3
ORDER BY sm_type, total_net_loss DESC
