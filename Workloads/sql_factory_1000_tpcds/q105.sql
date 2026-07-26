SELECT s.s_store_sk,
       s.s_store_name,
       i.i_brand,
       i.i_brand_id,
       sr.sr_returned_date_sk,
       SUM(sr.sr_net_loss) AS daily_net_loss,
       LAG(SUM(sr.sr_net_loss)) OVER (PARTITION BY s.s_store_sk, i.i_brand_id ORDER BY sr.sr_returned_date_sk) AS prev_day_loss,
       CASE WHEN SUM(sr.sr_net_loss) > COALESCE(LAG(SUM(sr.sr_net_loss)) OVER (PARTITION BY s.s_store_sk, i.i_brand_id ORDER BY sr.sr_returned_date_sk),0) * 1.5 THEN 'Spike' ELSE 'Normal' END AS loss_trend
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE sr.sr_returned_date_sk >= 20230601
GROUP BY s.s_store_sk, s.s_store_name, i.i_brand, i.i_brand_id, sr.sr_returned_date_sk
ORDER BY s.s_store_sk, i.i_brand_id, sr.sr_returned_date_sk DESC
LIMIT 100
