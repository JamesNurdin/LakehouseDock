SELECT td.t_hour,
       td.t_shift,
       COUNT(DISTINCT wr.wr_order_number) AS num_returns,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_net_loss) AS total_net_loss,
       AVG(p.p_cost) AS avg_promo_cost,
       SUM(CASE WHEN p.p_discount_active = 'Y' THEN wr.wr_return_amt * (p.p_cost / 100) ELSE 0 END) AS discount_impact
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
LEFT JOIN promotion p ON p.p_item_sk = wr.wr_item_sk
                     AND wr.wr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE td.t_hour BETWEEN 9 AND 18
  AND p.p_channel_tv = 'N'
GROUP BY td.t_hour, td.t_shift
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 50
