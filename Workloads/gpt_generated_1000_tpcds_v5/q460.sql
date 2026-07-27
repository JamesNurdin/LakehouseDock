SELECT s_store_id,
       s_store_name,
       s_state,
       s_tax_percentage
FROM tpcds.store
WHERE s_tax_percentage = 0.08
  AND s_market_id = 5
LIMIT 100
