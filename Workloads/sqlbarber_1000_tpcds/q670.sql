SELECT d.d_year AS year,
       w.wp_type AS page_type,
       SUM(p.p_cost) AS total_promo_cost,
       COUNT(DISTINCT p.p_promo_sk) AS promo_count
FROM web_page w
JOIN date_dim d ON w.wp_creation_date_sk = d.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 1924
  AND w.wp_type = 'feedback                                          '
GROUP BY d.d_year, w.wp_type
ORDER BY d.d_year, w.wp_type
