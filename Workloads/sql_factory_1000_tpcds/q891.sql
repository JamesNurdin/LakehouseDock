WITH daily_metrics AS (
 SELECT d.d_date,
        d.d_year,
        CASE WHEN d.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
        COUNT(DISTINCT p.p_promo_sk) AS active_promo_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(DISTINCT ws.web_site_sk) AS active_site_cnt
 FROM date_dim d
 LEFT JOIN promotion p ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
 LEFT JOIN web_site ws ON d.d_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
 WHERE d.d_year BETWEEN 2020 AND 2022
 GROUP BY d.d_date, d.d_year, d.d_weekend
)
SELECT d_date,
       d_year,
       day_type,
       active_promo_cnt,
       total_promo_cost,
       active_site_cnt,
       CASE WHEN active_promo_cnt = 0 THEN 0 ELSE total_promo_cost / active_promo_cnt END AS avg_cost_per_promo,
       SUM(total_promo_cost) OVER (PARTITION BY d_year ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_cost_year,
       DENSE_RANK() OVER (ORDER BY total_promo_cost DESC) AS cost_rank_overall,
       ROW_NUMBER() OVER (ORDER BY total_promo_cost DESC) AS cost_rownum
FROM daily_metrics
WHERE active_promo_cnt > 0
ORDER BY d_year, d_date
