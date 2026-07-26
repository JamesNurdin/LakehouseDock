SELECT s.s_store_sk,
       s.s_store_name,
       i.i_brand,
       i.i_brand_id,
       sr.sr_returned_date_sk,
       COUNT(*) AS returns_count,
       SUM(sr.sr_return_quantity) AS total_quantity,
       MAX(sr.sr_net_loss) AS max_loss,
       MIN(sr.sr_net_loss) AS min_loss,
       (MAX(sr.sr_net_loss) - MIN(sr.sr_net_loss)) / NULLIF(COUNT(*),0) AS loss_variability
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE sr.sr_returned_date_sk IS NOT NULL AND i.i_category = 'Electronics'
GROUP BY s.s_store_sk, s.s_store_name, i.i_brand, i.i_brand_id, sr.sr_returned_date_sk
HAVING COUNT(*) > 5
ORDER BY loss_variability DESC
LIMIT 100
