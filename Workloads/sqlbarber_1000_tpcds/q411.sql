SELECT p.p_promo_name,
       SUM(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
WHERE p.p_start_date_sk >= 2450848 AND p.p_end_date_sk <= 2450856
GROUP BY p.p_promo_name
ORDER BY total_net_paid DESC
