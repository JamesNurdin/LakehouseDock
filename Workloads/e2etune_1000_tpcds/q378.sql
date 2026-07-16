SELECT state,
       market_class,
       num_call_centers,
       avg_employees,
       total_web_tax,
       total_promo_cost,
       RANK() OVER (PARTITION BY state ORDER BY total_promo_cost DESC) AS promo_cost_rank
FROM (
    SELECT cc.cc_state AS state,
           cc.cc_mkt_class AS market_class,
           COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
           AVG(cc.cc_employees) AS avg_employees,
           SUM(ws.web_tax_percentage) AS total_web_tax,
           SUM(p.p_cost) AS total_promo_cost
    FROM call_center cc
    JOIN web_site ws
      ON cc.cc_state = ws.web_state
     AND cc.cc_city = ws.web_city
     AND cc.cc_zip = ws.web_zip
    LEFT JOIN promotion p
      ON p.p_start_date_sk BETWEEN cc.cc_open_date_sk AND COALESCE(cc.cc_closed_date_sk, 99999999)
    WHERE cc.cc_gmt_offset BETWEEN -5 AND 0
      AND cc.cc_employees > 0
      AND ws.web_gmt_offset BETWEEN -5 AND 0
      AND (p.p_cost > 1000 OR p.p_cost IS NULL)
    GROUP BY cc.cc_state, cc.cc_mkt_class
    HAVING COUNT(DISTINCT cc.cc_call_center_id) >= 2
) t
ORDER BY total_promo_cost DESC
LIMIT 100
