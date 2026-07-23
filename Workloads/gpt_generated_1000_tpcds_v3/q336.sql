WITH inventory_summary AS (
  SELECT
    inv.inv_date_sk,
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand,
    d.d_date,
    i.i_category,
    i.i_item_id,
    w.w_warehouse_name
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2002
    AND i.i_category = 'Sports'
    AND w.w_state = 'CA'
    AND inv.inv_quantity_on_hand > 0
)
SELECT
  cr.cr_order_number,
  cr.cr_return_amt_inc_tax,
  cr.cr_net_loss,
  d_ret.d_date AS return_date,
  i.i_item_id,
  i.i_product_name,
  i.i_category,
  w_ret.w_warehouse_name,
  r.r_reason_desc,
  cd_ref.cd_gender AS refunded_customer_gender,
  cd_ret.cd_gender AS returning_customer_gender,
  inv_sum.inv_quantity_on_hand,
  CASE
    WHEN inv_sum.inv_quantity_on_hand = 0 THEN NULL
    ELSE cr.cr_return_amt_inc_tax / inv_sum.inv_quantity_on_hand
  END AS return_amount_per_quantity,
  RANK() OVER (PARTITION BY i.i_category ORDER BY cr.cr_return_amt_inc_tax DESC) AS category_return_rank,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cr.cr_return_amt_inc_tax DESC) AS category_return_row_num,
  AVG(cr.cr_return_amt_inc_tax) OVER (PARTITION BY i.i_category ORDER BY d_ret.d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_returns,
  (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = cr.cr_item_sk) AS total_returns_for_item
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
LEFT JOIN inventory_summary inv_sum
  ON inv_sum.inv_item_sk = cr.cr_item_sk
  AND inv_sum.inv_date_sk = cr.cr_returned_date_sk
  AND inv_sum.inv_warehouse_sk = cr.cr_warehouse_sk
WHERE d_ret.d_year = 2002
  AND cr.cr_return_amt_inc_tax > 100
  AND r.r_reason_desc LIKE '%defective%'
  AND w_ret.w_city = 'San Francisco'
ORDER BY cr.cr_return_amt_inc_tax DESC, d_ret.d_date
LIMIT 100
