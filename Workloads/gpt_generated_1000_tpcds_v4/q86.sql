SELECT DISTINCT i.i_category,
       i.i_manager_id,
       i.i_units
FROM tpcds.catalog_returns cr
JOIN tpcds.item i
  ON cr.cr_item_sk = i.i_item_sk
WHERE cr.cr_return_tax > 10
  AND i.i_units = 'Lb'
ORDER BY i.i_category, i.i_manager_id
LIMIT 100
