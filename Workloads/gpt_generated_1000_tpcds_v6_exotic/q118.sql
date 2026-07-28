WITH joined_data AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_order_number,
    cr.cr_return_quantity,
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    i.i_rec_start_date,
    i.i_rec_end_date,
    cp.cp_department,
    cp.cp_type,
    inv.inv_quantity_on_hand,
    pr.p_promo_name,
    pr.p_channel_email
  FROM catalog_returns cr
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
  JOIN promotion pr
    ON i.i_item_sk = pr.p_item_sk
  WHERE
    pr.p_channel_email = 'Y'
    AND cp.cp_type = 'quarterly'
    AND i.i_rec_start_date >= DATE '2001-01-01'
    AND cr.cr_return_amount > 50.00
)
SELECT
  cp_department,
  i_brand,
  p_promo_name,
  COUNT(DISTINCT cr_order_number) AS distinct_orders,
  SUM(cr_return_amount) AS total_return_amount,
  AVG(inv_quantity_on_hand) AS avg_quantity_on_hand,
  MAX(cr_return_tax) AS max_return_tax,
  MIN(i_rec_end_date) AS earliest_end_date
FROM joined_data
GROUP BY
  cp_department,
  i_brand,
  p_promo_name
ORDER BY total_return_amount DESC
LIMIT 100
