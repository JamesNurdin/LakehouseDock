SELECT s.s_store_id,
       s.s_state,
       t.t_hour,
       hd.hd_buy_potential,
       COUNT(*) AS return_cnt,
       SUM(sr.sr_return_amt) AS total_return_amt,
       SUM(sr.sr_net_loss) AS total_net_loss,
       AVG(sr.sr_return_quantity) AS avg_qty,
       SUM(sr.sr_return_amt) / NULLIF(COUNT(*), 0) AS avg_return_amt
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE s.s_state = 'CA'
  AND t.t_shift = 'Evening'
  AND hd.hd_buy_potential = 'HIGH'
  AND ca.ca_country = 'United States'
GROUP BY s.s_store_id, s.s_state, t.t_hour, hd.hd_buy_potential
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
