WITH promo_quarter AS (
 SELECT ws.web_site_sk,
        ws.web_name,
        d_quarter.d_year,
        d_quarter.d_quarter_seq,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(p.p_promo_sk) AS promo_cnt,
        AVG(p.p_cost) AS avg_promo_cost
 FROM promotion p
 JOIN date_dim d_quarter ON p.p_start_date_sk = d_quarter.d_date_sk
 JOIN web_site ws ON p.p_start_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
 GROUP BY ws.web_site_sk, ws.web_name, d_quarter.d_year, d_quarter.d_quarter_seq
)
SELECT web_site_sk,
       web_name,
       d_year,
       d_quarter_seq,
       total_promo_cost,
       promo_cnt,
       avg_promo_cost,
       CASE WHEN total_promo_cost > 50000 THEN 'High' WHEN total_promo_cost > 20000 THEN 'Medium' ELSE 'Low' END AS cost_category,
       RANK() OVER (PARTITION BY d_year ORDER BY total_promo_cost DESC) AS year_quarter_site_rank,
       DENSE_RANK() OVER (ORDER BY total_promo_cost DESC) AS overall_site_rank
FROM promo_quarter
WHERE promo_cnt > 0
ORDER BY d_year, d_quarter_seq
