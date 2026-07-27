SELECT i.i_product_name,
       i.i_brand,
       sr.sr_return_amt_inc_tax,
       sr.sr_return_quantity
FROM tpcds.store_returns sr
JOIN tpcds.item i
  ON sr.sr_item_sk = i.i_item_sk
WHERE i.i_size = 'medium'
  AND sr.sr_return_amt_inc_tax > 100
ORDER BY sr.sr_return_amt_inc_tax DESC
LIMIT 100
