SELECT
    cc.cc_name,
    cc.cc_state,
    i.i_category,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_response_target) AS avg_response_target,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(p.p_cost) DESC) AS category_cost_rank
FROM call_center AS cc
JOIN date_dim AS cc_open_dd ON cc.cc_open_date_sk = cc_open_dd.d_date_sk
JOIN date_dim AS cc_closed_dd ON cc.cc_closed_date_sk = cc_closed_dd.d_date_sk
CROSS JOIN promotion AS p
JOIN date_dim AS p_start_dd ON p.p_start_date_sk = p_start_dd.d_date_sk
JOIN date_dim AS p_end_dd ON p.p_end_date_sk = p_end_dd.d_date_sk
JOIN item AS i ON p.p_item_sk = i.i_item_sk
WHERE p_start_dd.d_date BETWEEN cc_open_dd.d_date AND cc_closed_dd.d_date
  AND p_start_dd.d_year = 2000
  AND p.p_discount_active = 'Y'
  AND cc.cc_state IN ('CA', 'NY', 'TX')
GROUP BY cc.cc_name, cc.cc_state, i.i_category
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 100
