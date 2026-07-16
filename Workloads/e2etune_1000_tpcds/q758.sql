SELECT i.i_category,
       d_start.d_year AS promo_start_year,
       COUNT(p.p_promo_id) AS promo_cnt,
       SUM(p.p_cost) AS total_cost,
       AVG(p.p_cost) AS avg_cost,
       AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_duration_days,
       RANK() OVER (PARTITION BY d_start.d_year ORDER BY SUM(p.p_cost) DESC) AS rank_by_cost
FROM promotion p
JOIN item i ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d_start.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND i.i_wholesale_cost > 10
  AND d_start.d_year >= 2010
GROUP BY i.i_category, d_start.d_year
ORDER BY d_start.d_year, rank_by_cost
