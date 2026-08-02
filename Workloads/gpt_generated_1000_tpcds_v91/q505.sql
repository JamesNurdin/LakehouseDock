WITH intersected_stores AS (
  SELECT DISTINCT ss.ss_store_sk AS store_sk
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE ss.ss_net_profit > 0
    AND regexp_like(s.s_manager, '^J')
    AND s.s_street_type LIKE '%Road%'
  INTERSECT
  SELECT DISTINCT sr.sr_store_sk AS store_sk
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE sr.sr_net_loss > 0
    AND regexp_like(s.s_manager, '^J')
    AND s.s_street_type LIKE '%Road%'
)
SELECT
  s.s_store_id,
  s.s_store_name,
  CONCAT(s.s_city, ', ', s.s_state) AS city_state,
  SUM(ss.ss_net_profit) AS total_net_profit,
  AVG(sr.sr_net_loss) AS avg_net_loss,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_ticket_cnt,
  MIN(regexp_extract(hd.hd_buy_potential, '(\\w+)', 1)) AS first_buy_potential_word,
  (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS avg_net_profit_all_stores
FROM intersected_stores i
JOIN store s ON i.store_sk = s.s_store_sk
JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
  AND ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_item_sk = sr.sr_item_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count > 2
  AND hd.hd_income_band_sk BETWEEN 5 AND 10
GROUP BY
  s.s_store_id,
  s.s_store_name,
  s.s_city,
  s.s_state
ORDER BY total_net_profit DESC
LIMIT 100
