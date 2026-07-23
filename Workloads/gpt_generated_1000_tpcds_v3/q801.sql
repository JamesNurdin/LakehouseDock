SELECT DISTINCT i.i_item_id, i.i_product_name
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE i.i_manager_id = 63
  AND sr.sr_store_credit > 30
ORDER BY i.i_item_id
