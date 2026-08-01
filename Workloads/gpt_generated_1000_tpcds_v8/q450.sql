SELECT i.i_item_id,
       i.i_brand,
       cr.cr_return_amount,
       cr.cr_fee
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
WHERE i.i_brand_id = 1002001
  AND cr.cr_fee > 20.00
ORDER BY cr.cr_return_amount DESC
LIMIT 100
